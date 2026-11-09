<?php

namespace CiviCRM\Sniffs\Database;

use PHP_CodeSniffer\Files\File;
use PHP_CodeSniffer\Sniffs\Sniff;
use PHP_CodeSniffer\Util\Tokens;

/**
 * Reports a CRM_Core_Transaction that is rolled back for exceptions only. A PHP
 * error passes such a catch, and the transaction commits when it is destroyed.
 */
class TransactionRollbackSniff implements Sniff {

    /**
     * Returns the token types this sniff listens for.
     *
     * @return array<int>
     */
    public function register()
    {
        return [T_CATCH];
    }

    /**
     * Processes a catch block.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the catch.
     *
     * @return void
     */
    public function process(File $phpcsFile, $stackPtr)
    {
        $tokens = $phpcsFile->getTokens();
        if (!isset($tokens[$stackPtr]['scope_opener']) || $this->catchesErrors($phpcsFile, $stackPtr)) {
            return;
        }

        foreach ($this->rolledBackVariables($phpcsFile, $stackPtr) as $variable) {
            if ($this->isTransaction($phpcsFile, $stackPtr, $variable) && !$this->isRolledBackOnError($phpcsFile, $stackPtr, $variable)) {
                $warning = 'Transaction %s is rolled back for exceptions only; a PHP error commits it when it is destroyed. Catch \Throwable';
                $phpcsFile->addWarning($warning, $stackPtr, 'ExceptionOnly', [$variable]);
                return;
            }
        }
    }

    /**
     * Whether this or a surrounding try rolls the variable back for \Error.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $catch The position of the catch.
     * @param string $variable The variable name.
     *
     * @return bool
     */
    private function isRolledBackOnError(File $phpcsFile, $catch, $variable)
    {
        foreach ($this->enclosingTries($phpcsFile, $catch) as $try) {
            if ($this->tryHandlesErrors($phpcsFile, $try, $variable)) {
                return TRUE;
            }
        }

        return FALSE;
    }

    /**
     * Whether the catch covers \Error.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $catch The position of the catch.
     *
     * @return bool
     */
    private function catchesErrors(File $phpcsFile, $catch)
    {
        $tokens = $phpcsFile->getTokens();
        $types = $phpcsFile->getTokensAsString(
            ($tokens[$catch]['parenthesis_opener'] + 1),
            ($tokens[$catch]['parenthesis_closer'] - $tokens[$catch]['parenthesis_opener'] - 1)
        );
        return preg_match('/(^|[\s|\\\\])(Throwable|Error)\b/i', $types) === 1;
    }

    /**
     * Returns the variables that a catch or finally block rolls back.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $block The position of the catch or finally.
     *
     * @return array<string>
     */
    private function rolledBackVariables(File $phpcsFile, $block)
    {
        $tokens = $phpcsFile->getTokens();
        $variables = [];
        for ($i = $tokens[$block]['scope_opener']; $i < $tokens[$block]['scope_closer']; $i++) {
            if ($tokens[$i]['code'] === T_STRING && strtolower($tokens[$i]['content']) === 'rollback'
      && $tokens[($i - 1)]['code'] === T_OBJECT_OPERATOR
      && $tokens[($i - 2)]['code'] === T_VARIABLE
      ) {
                $variables[] = $tokens[($i - 2)]['content'];
            }
        }

        return array_unique($variables);
    }

    /**
     * Whether the variable holds a new CRM_Core_Transaction in the same function.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $catch The position of the catch.
     * @param string $variable The variable name.
     *
     * @return bool
     */
    private function isTransaction(File $phpcsFile, $catch, $variable)
    {
        $tokens = $phpcsFile->getTokens();
        $start = 0;
        foreach ($tokens[$catch]['conditions'] as $ptr => $code) {
            if ($code === T_FUNCTION || $code === T_CLOSURE) {
                $start = $ptr;
            }
        }

        for ($i = $start; $i < $catch; $i++) {
            if ($tokens[$i]['code'] !== T_VARIABLE || $tokens[$i]['content'] !== $variable) {
                continue;
            }

            $equal = $phpcsFile->findNext(Tokens::$emptyTokens, ($i + 1), NULL, TRUE);
            $new = $phpcsFile->findNext(Tokens::$emptyTokens, ($equal + 1), NULL, TRUE);
            if ($tokens[$equal]['code'] !== T_EQUAL || $tokens[$new]['code'] !== T_NEW) {
                continue;
            }

            $class = $phpcsFile->findNext(array_merge(Tokens::$emptyTokens, [T_NS_SEPARATOR]), ($new + 1), NULL, TRUE);
            if ($tokens[$class]['content'] === 'CRM_Core_Transaction') {
                return TRUE;
            }
        }

        return FALSE;
    }

    /**
     * Returns the try of this catch and every try around it in the same function.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $catch The position of the catch.
     *
     * @return array<int>
     */
    private function enclosingTries(File $phpcsFile, $catch)
    {
        $tokens = $phpcsFile->getTokens();
        $tries = [];
        foreach ($tokens[$catch]['conditions'] as $ptr => $code) {
            if ($code === T_FUNCTION || $code === T_CLOSURE) {
                $tries = [];
            }
elseif ($code === T_TRY) {
                $tries[] = $ptr;
}
        }

        $previous = $catch;
        do {
            $closer = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($previous - 1), NULL, TRUE);
            $previous = $tokens[$closer]['scope_condition'];
        } while ($tokens[$previous]['code'] === T_CATCH);

        $tries[] = $previous;
        return $tries;
    }

    /**
     * Whether a try has a catch for \Error or a finally that rolls back the variable.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $try The position of the try.
     * @param string $variable The variable name.
     *
     * @return bool
     */
    private function tryHandlesErrors(File $phpcsFile, $try, $variable)
    {
        $tokens = $phpcsFile->getTokens();
        $closer = $tokens[$try]['scope_closer'];
        while (TRUE) {
            $next = $phpcsFile->findNext(Tokens::$emptyTokens, ($closer + 1), NULL, TRUE);
            if ($next === FALSE || !in_array($tokens[$next]['code'], [T_CATCH, T_FINALLY], TRUE)) {
                return FALSE;
            }

            $coversErrors = $tokens[$next]['code'] === T_FINALLY || $this->catchesErrors($phpcsFile, $next);
            if ($coversErrors && in_array($variable, $this->rolledBackVariables($phpcsFile, $next), TRUE)) {
                return TRUE;
            }

            $closer = $tokens[$next]['scope_closer'];
        }
    }

}

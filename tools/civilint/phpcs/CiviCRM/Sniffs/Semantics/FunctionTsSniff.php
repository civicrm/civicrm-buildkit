<?php

namespace CiviCRM\Sniffs\Semantics;

use Drupal\Sniffs\Semantics\FunctionTSniff;
use PHP_CodeSniffer\Files\File;
use PHP_CodeSniffer\Util\Tokens;

/**
 * Applies Drupal's translatable string checks to ts() and E::ts(), and adds
 * the CiviCRM translation best practices that can be checked statically.
 */
class FunctionTsSniff extends FunctionTSniff {

    /**
     * Returns an array of function names this test wants to listen for.
     *
     * @return array<string>
     */
    public function registerFunctionNames()
    {
        return ['ts'];
    }

    /**
     * Processes this function call.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the function call.
     * @param int $openBracket The position of the opening parenthesis.
     * @param int $closeBracket The position of the closing parenthesis.
     *
     * @return void
     */
    public function processFunctionCall(File $phpcsFile, $stackPtr, $openBracket, $closeBracket)
    {
        if (self::isForeignMethod($phpcsFile, $stackPtr) || $this->isInsideWrapper($phpcsFile, $stackPtr)) {
            return;
        }

        parent::processFunctionCall($phpcsFile, $stackPtr, $openBracket, $closeBracket);

        $tokens = $phpcsFile->getTokens();
        $argument = $this->getArgument(1);
        if ($argument !== FALSE
    && $tokens[$argument['start']]['code'] === T_CONSTANT_ENCAPSED_STRING
    && !in_array($tokens[$argument['start']]['content'], ['""', "''"], TRUE)
    ) {
            $this->checkString($phpcsFile, $argument);
        }
    }

    /**
     * Only E::ts() and *ExtensionUtil::ts() translate; self::ts() or $obj->ts()
     * are unrelated methods.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the function name.
     *
     * @return bool
     */
    public static function isForeignMethod(File $phpcsFile, $stackPtr)
    {
        $tokens = $phpcsFile->getTokens();
        $previous = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($stackPtr - 1), NULL, TRUE);
        if ($tokens[$previous]['code'] === T_OBJECT_OPERATOR || $tokens[$previous]['code'] === T_NULLSAFE_OBJECT_OPERATOR) {
            return TRUE;
        }

        if ($tokens[$previous]['code'] !== T_DOUBLE_COLON) {
            return FALSE;
        }

        $class = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($previous - 1), NULL, TRUE);
        $class = ltrim($tokens[$class]['content'], '\\');
        return $class !== 'E' && substr($class, -strlen('ExtensionUtil')) !== 'ExtensionUtil';
    }

    /**
     * The civix-generated ts() and the Smarty block plugin pass their parameters through.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the function name.
     *
     * @return bool
     */
    private function isInsideWrapper(File $phpcsFile, $stackPtr)
    {
        $function = $phpcsFile->getCondition($stackPtr, T_FUNCTION);
        return $function !== FALSE
            && in_array($phpcsFile->getDeclarationName($function), ['ts', 'smarty_block_ts'], TRUE);
    }

    /**
     * Checks a ts() string against the CiviCRM translation best practices.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param array $argument The first argument of the call.
     *
     * @return void
     */
    private function checkString(File $phpcsFile, array $argument)
    {
        // PHPCS splits a string literal that spans lines into one token per line.
        $tokens = $phpcsFile->getTokens();
        $literal = '';
        for ($i = $argument['start']; $i <= $argument['end'] && $tokens[$i]['code'] === T_CONSTANT_ENCAPSED_STRING; $i++) {
            $literal .= $tokens[$i]['content'];
        }

        $message = substr($literal, 1, -1);
        if (strpos($message, "\n") !== FALSE || ($literal[0] === '"' && strpos($message, '\n') !== FALSE)) {
            $warning = 'Translatable strings must not contain line breaks, keep the ts() string on a single line';
            $phpcsFile->addWarning($warning, $argument['start'], 'LineBreak');
        }

        // Inline markup such as links or emphasis stays in the string, so sentences are not split.
        if (preg_match('/<\/?(p|div|br|hr|ul|ol|li|dl|dt|dd|table|thead|tbody|tfoot|tr|th|td|pre|blockquote|h[1-6])(\s[^>]*)?\/?>/i', $message) === 1) {
            $warning = 'Translatable strings must not contain block-level HTML such as paragraphs, line breaks, lists or tables, put the markup around ts() and translate each paragraph separately';
            $phpcsFile->addWarning($warning, $argument['start'], 'BlockTag');
        }

        // Several placeholders without words still let translators reorder them.
        if (preg_match('/^(%\d+|\d+)?$/', preg_replace('/\s/', '', $message)) === 1) {
            $warning = 'Translatable strings must contain words, do not pass a lone placeholder or number to ts()';
            $phpcsFile->addWarning($warning, $argument['start'], 'NoWords');
        }
    }

    /**
     * Checks if a string can be concatenated with a translatable string.
     *
     * CiviCRM also embeds ts() in markup, SQL, JavaScript and Smarty strings, and
     * uses it for file names.
     *
     * @param string $string The string that is concatenated to a ts() call.
     *
     * @return bool
     */
    protected function checkConcatString($string)
    {
        if (parent::checkConcatString($string)) {
            return TRUE;
        }

        $string = substr($string, 1, -1);

        // A file extension, or a quote that closes the string around the ts() call.
        if (preg_match('/^(\.[a-z0-9]+$|[)\]]*["\']|\{\/?[a-z])/i', $string) === 1) {
            return TRUE;
        }

        $string = preg_replace('/\\\\n|&nbsp;|\s/', '', strip_tags($string));
        return $string === '' || $string === '|';
    }

}

<?php

namespace CiviCRM\Sniffs\Database;

use CiviCRM\Sniffs\Semantics\TsPlaceholdersSniff;
use PHP_CodeSniffer\Files\File;
use PHP_CodeSniffer\Util\Tokens;
use PHPCSUtils\Utils\PassedParameters;
use PHPCSUtils\Utils\TextStrings;

/**
 * Checks the numbered placeholders of a CRM_Core_DAO query against its parameter
 * array, following how CRM_Core_DAO::composeQuery() applies strtr().
 */
class QueryPlaceholdersSniff extends TsPlaceholdersSniff {

    /**
     * A placeholder at the start of the SQL or after an operator, bracket, comma or keyword.
     *
     * @var string
     */
    private const PLACEHOLDER = '/(?:^|[=<>(,+\-*\/!]|\b(?:SELECT|DISTINCT|FROM|JOIN|INTO|UPDATE|TABLE|SET|VALUES|WHERE|HAVING|ON|AND|OR|NOT|IN|LIKE|REGEXP|BETWEEN|BY|LIMIT|OFFSET|AS|CASE|WHEN|THEN|ELSE)\b)\s*%([0-9]+)/i';

    /**
     * Returns an array of function names this test wants to listen for.
     *
     * @return array<string>
     */
    public function registerFunctionNames()
    {
        return ['executeQuery', 'executeUnbufferedQuery', 'singleValueQuery', 'composeQuery'];
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
        if (!$this->isDaoCall($phpcsFile, $stackPtr)) {
            return;
        }

        $args = PassedParameters::getParameters($phpcsFile, $stackPtr);
        if (!isset($args[2])) {
            return;
        }

        $params = $this->parseArray($phpcsFile, $args[2]);
        if ($params === FALSE) {
            return;
        }

        $sql = $this->literalSql($phpcsFile, $args[1]);

        // String keys are ignored by composeQuery(). PHP numbers elements without a key.
        $keys = [];
        $positional = [];
        $nextIndex = 0;
        foreach ($params['elements'] as $element) {
            if ($element['key'] === NULL) {
                if ($nextIndex === 0) {
                    $positional[] = $element;
                }
else {
                    $keys[$nextIndex] = $element;
}

                $nextIndex++;
            }
elseif (is_int($element['key'])) {
                $keys[$element['key']] = $element;
                $nextIndex = max($nextIndex, ($element['key'] + 1));
}
        }

        // A computed key shifts the numbering, and unknown SQL may use %0 on purpose.
        if ($params['dynamic'] || $sql === NULL) {
            return;
        }

        foreach ($positional as $element) {
            if (preg_match('/%0(?![0-9])/', $sql) === 1) {
                $keys[0] = $element;
            }
else {
                $error = 'Query parameter without a key is substituted for %%0; use [1 => [$value, $type]]';
                $phpcsFile->addError($error, $element['start'], 'PositionalParam');
}
        }

        $this->compareWithSql($phpcsFile, $args[1]['start'], $sql, $keys);
    }

    /**
     * Reports placeholders without a parameter and parameters without a placeholder.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $sqlPtr Start of the SQL argument.
     * @param string $sql The SQL without PHP quotes.
     * @param array $keys The parameters by integer key.
     *
     * @return void
     */
    private function compareWithSql(File $phpcsFile, $sqlPtr, $sql, array $keys)
    {
        $used = [];
        preg_match_all('/%([0-9]+)/', $sql, $matches);
        foreach ($matches[1] as $digits) {
            $used[] = $this->matchNumericKey($digits, $keys);
        }

        // A %1 in a string or comment may be literal text; after an operand, %2 is the modulo operator.
        $code = preg_replace('/\'(?:[^\'\\\\]|\\\\.)*\'|"(?:[^"\\\\]|\\\\.)*"|\/\*.*?\*\/|(?:--\s|#)[^\n]*/s', "''", $sql);
        preg_match_all(self::PLACEHOLDER, $code, $matches);
        foreach (array_unique($matches[1]) as $digits) {
            if ($this->matchNumericKey($digits, $keys) === NULL) {
                $error = 'Query contains %%%s but the parameters have no key %s';
                $phpcsFile->addError($error, $sqlPtr, 'MissingParam', [$digits, $digits]);
            }
        }

        foreach ($keys as $key => $element) {
            if (!in_array($key, $used, TRUE)) {
                $warning = 'Query parameter %s is not used in the SQL';
                $phpcsFile->addWarning($warning, $element['keyPtr'], 'UnusedParam', [$key]);
            }
        }
    }

    /**
     * Only CRM_Core_DAO has this parameter format.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the function name.
     *
     * @return bool
     */
    private function isDaoCall(File $phpcsFile, $stackPtr)
    {
        $tokens = $phpcsFile->getTokens();
        $colon = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($stackPtr - 1), NULL, TRUE);
        if ($tokens[$colon]['code'] !== T_DOUBLE_COLON) {
            return FALSE;
        }

        $class = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($colon - 1), NULL, TRUE);
        return ltrim($tokens[$class]['content'], '\\') === 'CRM_Core_DAO';
    }

    /**
     * Returns the SQL of an argument made of one string literal, which PHPCS
     * splits into one token per line.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param array $arg The argument as PassedParameters returns it.
     *
     * @return string|null
     */
    private function literalSql(File $phpcsFile, array $arg)
    {
        $tokens = $phpcsFile->getTokens();
        $literal = '';
        for ($i = $arg['start']; $i <= $arg['end']; $i++) {
            if (isset(Tokens::$emptyTokens[$tokens[$i]['code']])) {
                continue;
            }

            if ($tokens[$i]['code'] !== T_CONSTANT_ENCAPSED_STRING) {
                return NULL;
            }

            $literal .= $tokens[$i]['content'];
        }

        return $literal === '' ? NULL : TextStrings::stripQuotes($literal);
    }

}

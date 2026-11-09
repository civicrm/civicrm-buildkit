<?php
/**
 * \CiviCRM\Sniffs\Semantics\TsPlaceholdersSniff
 *
 * @category PHP
 * @package  PHP_CodeSniffer
 * @link     http://pear.php.net/package/PHP_CodeSniffer
 */

namespace CiviCRM\Sniffs\Semantics;

use Drupal\Sniffs\Semantics\FunctionCall;
use PHP_CodeSniffer\Files\File;
use PHP_CodeSniffer\Util\Tokens;
use PHPCSUtils\Utils\Arrays;
use PHPCSUtils\Utils\Numbers;
use PHPCSUtils\Utils\PassedParameters;
use PHPCSUtils\Utils\TextStrings;

/**
 * Checks that the placeholders of a CiviCRM ts() / E::ts() string match the
 * replacements passed in its second argument.
 *
 * @category PHP
 * @package  PHP_CodeSniffer
 * @link     http://pear.php.net/package/PHP_CodeSniffer
 */
class TsPlaceholdersSniff extends FunctionCall {

    /**
     * Catch E::ts() in extensions, too.
     *
     * @var bool
     */
    protected $includeMethodCalls = TRUE;

    /**
     * Keys of the ts() params array that are options, not replacements.
     *
     * @var array
     */
    protected $optionKeys = [
      'escape',
      'skip',
      'raw',
      'plural',
      'context',
      'domain',
      'skip_translation',
    ];

    /**
     * Options that turn off placeholder substitution in crm_translate().
     *
     * @var array
     */
    protected $noSubstitutionKeys = [
      'skip',
      'raw',
    ];

    /**
     * Array keys of SearchKit task messages, whose placeholders JavaScript fills.
     *
     * @var array
     */
    protected $deferredKeys = [
      'confirmMsg',
      'runMsg',
      'successMsg',
      'errorMsg',
    ];

    /**
     * Returns an array of function names this test wants to listen for.
     *
     * @return array
     */
    public function registerFunctionNames()
    {
        return ['ts'];

    }//end registerFunctionNames()

    /**
     * Processes this function call.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the function call in the stack.
     * @param int $openBracket The position of the opening parenthesis in the stack.
     * @param int $closeBracket The position of the closing parenthesis in the stack.
     *
     * @return void
     */
    public function processFunctionCall(
        File $phpcsFile,
        $stackPtr,
        $openBracket,
        $closeBracket
    ) {
        if (FunctionTsSniff::isForeignMethod($phpcsFile, $stackPtr) === TRUE) {
            return;
        }

        $tokens  = $phpcsFile->getTokens();
        $args    = PassedParameters::getParameters($phpcsFile, $stackPtr);
        $textPtr = $this->literalString($phpcsFile, $args, 1);
        if ($textPtr === NULL) {
            return;
        }

        $message = TextStrings::stripQuotes($tokens[$textPtr]['content']);
        if (isset($args[2]) === FALSE) {
            $this->checkWithoutParams($phpcsFile, $stackPtr, $textPtr, $message, $closeBracket);
            return;
        }

        $params = $this->parseArray($phpcsFile, $args[2]);
        if ($params === FALSE) {
            // Params are not an array literal, nothing to compare.
            return;
        }

        // PHP gives an element without a key the integer after the largest key so far.
        $nextIndex = 0;
        foreach ($params['elements'] as $position => $element) {
            if ($element['key'] === NULL) {
                if ($nextIndex === 0) {
                    $error = 'ts() replacement without a key is substituted for %0; use [1 => ...]';
                    $phpcsFile->addError($error, $element['start'], 'PositionalReplacement');
                }
else {
                    $params['elements'][$position]['key'] = $nextIndex;
}

                $nextIndex++;
            }
elseif (is_int($element['key']) === TRUE && $element['key'] >= $nextIndex) {
                $nextIndex = ($element['key'] + 1);
}
        }

        if ($params['dynamic'] === TRUE) {
            // A computed key or spread could provide any placeholder.
            return;
        }

        $keys = [];
        foreach ($params['elements'] as $element) {
            if ($element['key'] !== NULL) {
                $keys[$element['key']] = $element;
            }
        }

        foreach ($this->noSubstitutionKeys as $option) {
            if (isset($keys[$option]) === TRUE && $this->isFalsy($phpcsFile, $keys[$option]) === FALSE) {
                return;
            }
        }

        $haystack = $message;
        if (isset($keys['plural']) === TRUE) {
            $pluralPtr = $this->literalString($phpcsFile, [$keys['plural']], 0);
            if ($pluralPtr !== NULL) {
                $haystack .= "\n" . TextStrings::stripQuotes($tokens[$pluralPtr]['content']);
            }
        }

        $used = [];
        preg_match_all('/%(\d+)/', $haystack, $matches);
        foreach (array_unique($matches[1]) as $digits) {
            $key = $this->matchNumericKey($digits, $keys);
            if ($key !== NULL) {
                $used[] = $key;
            }
elseif ((strlen($digits) === 1 || (int) $digits <= $nextIndex)
      && $this->matchesStringKey($digits, $keys, $haystack) === FALSE
      ) {
                // Numbers with several digits beyond the replacements are URL encoding such as %20.
                $error = 'ts() string contains %%%s but the replacements have no key %s';
                $phpcsFile->addError($error, $textPtr, 'MissingReplacement', [$digits, $digits]);
}
        }

        if (isset($keys['plural']) === TRUE && $pluralPtr === NULL) {
            // A computed plural could use any replacement.
            return;
        }

        foreach ($keys as $key => $element) {
            if (in_array($key, $this->optionKeys, TRUE) === TRUE
      || ($key === 'count' && isset($keys['plural']) === TRUE)
      ) {
                continue;
            }

            if (is_int($key) === TRUE) {
                $isUsed = in_array($key, $used, TRUE);
            }
else {
                $isUsed = strpos($haystack, '%' . $key) !== FALSE;
}

            if ($isUsed === FALSE) {
                $error = 'ts() replacement %%%s is not used in the translatable string';
                $phpcsFile->addError($error, $element['keyPtr'], 'UnusedReplacement', [$key]);
            }
        }//end foreach

    }//end processFunctionCall()

    /**
     * Finds the key strtr() substitutes for "%<digits>": the longest prefix of
     * the digits that is a key.
     *
     * @param string $digits The digits after the percent sign.
     * @param array $keys The replacement keys.
     *
     * @return int|null
     */
    protected function matchNumericKey($digits, array $keys)
    {
        for ($length = strlen($digits); $length > 0; $length--) {
            $prefix = substr($digits, 0, $length);
            if (($prefix === '0' || $prefix[0] !== '0') && isset($keys[(int) $prefix]) === TRUE) {
                return (int) $prefix;
            }
        }

        return NULL;

    }//end matchNumericKey()

    /**
     * Whether a string key starting with these digits, e.g. '01', occurs as
     * a placeholder.
     *
     * @param string $digits The digits after the percent sign.
     * @param array $keys The replacement keys.
     * @param string $haystack The translatable strings.
     *
     * @return bool
     */
    protected function matchesStringKey($digits, array $keys, $haystack)
    {
        foreach (array_keys($keys) as $key) {
            if (is_string($key) === TRUE
      && strpos($key, $digits) === 0
      && strpos($haystack, '%' . $key) !== FALSE
      ) {
                return TRUE;
            }
        }

        return FALSE;

    }//end matchesStringKey()

    /**
     * Flags a ts() string with numbered placeholders but no replacements.
     *
     * Exempt: SearchKit task messages, whose placeholders JavaScript fills, and
     * strings assigned to a variable that str_replace() or strtr() fills later.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The ts token.
     * @param int $textPtr The translatable string token.
     * @param string $message The unquoted string.
     * @param int $closeBracket Closing parenthesis of ts().
     *
     * @return void
     */
    protected function checkWithoutParams(File $phpcsFile, $stackPtr, $textPtr, $message, $closeBracket)
    {
        // Placeholders start at %1; a lone %26 is more likely URL encoding.
        if (preg_match('/%1(?![0-9])/', $message) !== 1) {
            return;
        }

        $tokens = $phpcsFile->getTokens();
        $callee = [
          T_STRING,
          T_NS_SEPARATOR,
          T_DOUBLE_COLON,
          T_SELF,
          T_STATIC,
        ];
        $before = $phpcsFile->findPrevious(array_merge(Tokens::$emptyTokens, $callee), ($stackPtr - 1), NULL, TRUE);
        if ($tokens[$before]['code'] === T_DOUBLE_ARROW) {
            $key = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($before - 1), NULL, TRUE);
            if ($tokens[$key]['code'] === T_CONSTANT_ENCAPSED_STRING
      && in_array(TextStrings::stripQuotes($tokens[$key]['content']), $this->deferredKeys, TRUE) === TRUE
      ) {
                return;
            }
        }

        if ($this->isSubstitutedLater($phpcsFile, $before) === TRUE) {
            return;
        }

        if ($this->hasParamsOutside($phpcsFile, $stackPtr, $closeBracket) === TRUE) {
            $error = 'ts() string contains %1 but its replacements are passed outside ts(); move the array into the ts() call';
            $phpcsFile->addError($error, $textPtr, 'ParamsOutsideTs');
            return;
        }

        $error = 'ts() string contains %1 but no replacements are passed; add [1 => ...] as the second argument of ts()';
        $phpcsFile->addError($error, $textPtr, 'MissingReplacement');

    }//end checkWithoutParams()

    /**
     * Detects $var = ts('...'); followed by str_replace() or strtr() on $var
     * later in the same scope.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $before Token before the ts() callee.
     *
     * @return bool
     */
    protected function isSubstitutedLater(File $phpcsFile, $before)
    {
        $tokens = $phpcsFile->getTokens();
        if ($tokens[$before]['code'] !== T_EQUAL) {
            return FALSE;
        }

        $variable = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($before - 1), NULL, TRUE);
        if ($tokens[$variable]['code'] !== T_VARIABLE) {
            return FALSE;
        }

        $scopeEnd = $phpcsFile->numTokens;
        if (empty($tokens[$variable]['conditions']) === FALSE) {
            $scopes   = array_keys($tokens[$variable]['conditions']);
            $scopeEnd = $tokens[end($scopes)]['scope_closer'];
        }

        for ($i = ($before + 1); $i < $scopeEnd; $i++) {
            if ($tokens[$i]['code'] !== T_STRING
      || in_array(strtolower($tokens[$i]['content']), ['str_replace', 'strtr'], TRUE) === FALSE
      ) {
                continue;
            }

            foreach (PassedParameters::getParameters($phpcsFile, $i) as $arg) {
                $found = $phpcsFile->findNext(T_VARIABLE, $arg['start'], ($arg['end'] + 1), FALSE, $tokens[$variable]['content']);
                if ($found !== FALSE) {
                    return TRUE;
                }
            }
        }

        return FALSE;

    }//end isSubstitutedLater()

    /**
     * Detects foo(ts('... %1 ...'), [1 => $x]): the replacements are the next
     * argument of the enclosing call.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The ts token.
     * @param int $closeBracket Closing parenthesis of ts().
     *
     * @return bool
     */
    protected function hasParamsOutside(File $phpcsFile, $stackPtr, $closeBracket)
    {
        $tokens = $phpcsFile->getTokens();
        if (empty($tokens[$stackPtr]['nested_parenthesis']) === TRUE) {
            return FALSE;
        }

        $openers = array_keys($tokens[$stackPtr]['nested_parenthesis']);
        $callee  = $phpcsFile->findPrevious(Tokens::$emptyTokens, (end($openers) - 1), NULL, TRUE);
        if ($tokens[$callee]['code'] !== T_STRING) {
            // Not a function call, e.g. array( or if (.
            return FALSE;
        }

        $args = array_values(PassedParameters::getParameters($phpcsFile, $callee));
        foreach ($args as $index => $arg) {
            if ($arg['end'] < $closeBracket || isset($args[($index + 1)]) === FALSE) {
                continue;
            }

            // The whole argument must be the ts() call, not an array or expression.
            if ($phpcsFile->findPrevious(Tokens::$emptyTokens, $arg['end'], NULL, TRUE) !== $closeBracket) {
                return FALSE;
            }

            $params = $this->parseArray($phpcsFile, $args[($index + 1)]);
            if ($params === FALSE) {
                return FALSE;
            }

            foreach ($params['elements'] as $element) {
                if (is_int($element['key']) === TRUE && $this->matchNumericKey('1', [$element['key'] => TRUE]) !== NULL) {
                    return TRUE;
                }
            }

            return FALSE;
        }//end foreach

        return FALSE;

    }//end hasParamsOutside()

    /**
     * Returns the token of a parameter that is a single string literal.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param array $args Parameters as PassedParameters returns them.
     * @param int $index The parameter to check.
     *
     * @return int|null
     */
    protected function literalString(File $phpcsFile, array $args, $index)
    {
        if (isset($args[$index]) === FALSE) {
            return NULL;
        }

        $start = $phpcsFile->findNext(Tokens::$emptyTokens, $args[$index]['start'], ($args[$index]['end'] + 1), TRUE);
        $end   = $phpcsFile->findPrevious(Tokens::$emptyTokens, $args[$index]['end'], NULL, TRUE);
        if ($start !== $end || $phpcsFile->getTokens()[$start]['code'] !== T_CONSTANT_ENCAPSED_STRING) {
            return NULL;
        }

        return $start;

    }//end literalString()

    /**
     * Splits an array literal argument into its elements.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param array $arg The argument as PassedParameters returns it.
     *
     * @return array|false
     *   FALSE if the argument is not an array literal. Otherwise 'elements', each
     *   with 'key' (int, string or NULL when omitted), 'keyPtr' and the value's
     *   'start' and 'end', and 'dynamic' (TRUE if a key is computed or spread).
     */
    protected function parseArray(File $phpcsFile, array $arg)
    {
        $tokens = $phpcsFile->getTokens();
        $start  = $phpcsFile->findNext(Tokens::$emptyTokens, $arg['start'], ($arg['end'] + 1), TRUE);
        $end    = $phpcsFile->findPrevious(Tokens::$emptyTokens, $arg['end'], NULL, TRUE);
        if (in_array($tokens[$start]['code'], [T_OPEN_SHORT_ARRAY, T_ARRAY], TRUE) === FALSE) {
            return FALSE;
        }

        $openClose = Arrays::getOpenClose($phpcsFile, $start);
        if ($openClose === FALSE || $openClose['closer'] !== $end) {
            // A list, or something like [...] + $more.
            return FALSE;
        }

        $result = [
          'elements' => [],
          'dynamic'  => FALSE,
        ];
        foreach (PassedParameters::getParameters($phpcsFile, $start) as $item) {
            $first = $phpcsFile->findNext(Tokens::$emptyTokens, $item['start'], ($item['end'] + 1), TRUE);
            if ($tokens[$first]['code'] === T_ELLIPSIS) {
                $result['dynamic'] = TRUE;
                continue;
            }

            $element = [
              'key'    => NULL,
              'keyPtr' => $first,
              'start'  => $first,
              'end'    => $item['end'],
            ];
            $arrow   = Arrays::getDoubleArrowPtr($phpcsFile, $item['start'], $item['end']);
            if ($arrow !== FALSE) {
                $element['key']   = $this->literalKey($phpcsFile, $first, $arrow);
                $element['start'] = $phpcsFile->findNext(Tokens::$emptyTokens, ($arrow + 1), ($item['end'] + 1), TRUE);
                if ($element['key'] === NULL) {
                    $result['dynamic'] = TRUE;
                    continue;
                }
            }

            if ($element['key'] === NULL && $result['dynamic'] === TRUE) {
                // PHP numbers it from a computed key or spread, unknown here.
                continue;
            }

            $result['elements'][] = $element;
        }//end foreach

        return $result;

    }//end parseArray()

    /**
     * Whether an element's value is a literal PHP considers empty, e.g. FALSE or 0.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param array $element The element from parseArray().
     *
     * @return bool
     */
    protected function isFalsy(File $phpcsFile, array $element)
    {
        $tokens = $phpcsFile->getTokens();
        $end    = $phpcsFile->findPrevious(Tokens::$emptyTokens, $element['end'], NULL, TRUE);
        if ($element['start'] !== $end) {
            return FALSE;
        }

        $token = $tokens[$end];
        switch ($token['code']) {
        case T_FALSE:
        case T_NULL:
          return TRUE;

        case T_LNUMBER:
          return Numbers::getDecimalValue($token['content']) === '0';

        case T_CONSTANT_ENCAPSED_STRING:
          return in_array(TextStrings::stripQuotes($token['content']), ['', '0'], TRUE);

        default:
          return FALSE;
        }

    }//end isFalsy()

    /**
     * Returns the array key PHP would use, or NULL if it is not a plain literal.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $start First token of the key.
     * @param int $arrow The double arrow.
     *
     * @return int|string|null
     */
    protected function literalKey(File $phpcsFile, $start, $arrow)
    {
        if ($phpcsFile->findPrevious(Tokens::$emptyTokens, ($arrow - 1), NULL, TRUE) !== $start) {
            return NULL;
        }

        $content = $phpcsFile->getTokens()[$start]['content'];
        switch ($phpcsFile->getTokens()[$start]['code']) {
        case T_LNUMBER:
          return (int) Numbers::getDecimalValue($content);

        case T_CONSTANT_ENCAPSED_STRING:
            if (strpos($content, '\\') !== FALSE) {
                // Escape sequences are not decoded.
                return NULL;
            }

            $key = TextStrings::stripQuotes($content);
            if (preg_match('/^(0|[1-9][0-9]*)$/', $key) === 1) {
                return (int) $key;
            }
          return $key;

        default:
          return NULL;
        }

    }//end literalKey()

}//end class

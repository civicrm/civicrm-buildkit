<?php

namespace CiviCRM\Sniffs\Testing;

use PHP_CodeSniffer\Files\File;
use PHP_CodeSniffer\Sniffs\Sniff;
use PHP_CodeSniffer\Util\Tokens;

/**
 * Flags assertEquals() calls that compare against a literal expected value.
 *
 * assertEquals() compares loosely (==), so assertEquals(1, '1') and
 * assertEquals(TRUE, 'yes') pass. When the expected value is a literal,
 * assertSame() (or assertTrue()/assertFalse()/assertNull()) states the
 * intended type and catches type regressions.
 *
 * Reported as an error in CiviCRM core (including core extensions), whose
 * tests have been converted, and as a warning elsewhere.
 */
class AssertEqualsLiteralSniff implements Sniff
{

    /**
     * Cache of directory => whether it is inside a CiviCRM core checkout.
     *
     * @var array<string, bool>
     */
    private static $coreDirs = [];

    /**
     * Returns the token types that this sniff is interested in.
     *
     * @return array<int|string>
     */
    public function register()
    {
        return [T_STRING];
    }

    /**
     * Processes this sniff, when one of its tokens is encountered.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int                         $stackPtr  The position of the current token.
     *
     * @return void
     */
    public function process(File $phpcsFile, $stackPtr)
    {
        $tokens = $phpcsFile->getTokens();
        if ($tokens[$stackPtr]['content'] !== 'assertEquals') {
            return;
        }

        // Only method calls: $this->assertEquals(), self::/static::assertEquals().
        $prev = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($stackPtr - 1), null, true);
        if ($prev === false || in_array($tokens[$prev]['code'], [T_OBJECT_OPERATOR, T_NULLSAFE_OBJECT_OPERATOR, T_DOUBLE_COLON], true) === false) {
            return;
        }

        $open = $phpcsFile->findNext(Tokens::$emptyTokens, ($stackPtr + 1), null, true);
        if ($open === false || $tokens[$open]['code'] !== T_OPEN_PARENTHESIS || isset($tokens[$open]['parenthesis_closer']) === false) {
            return;
        }

        $args = $this->getArguments($phpcsFile, $open);
        if (count($args) < 2) {
            return;
        }

        $expected = $this->getLiteralKind($phpcsFile, $args[0]);
        $actual   = $this->getLiteralKind($phpcsFile, $args[1]);

        if ($expected !== null) {
            $message = 'Use %s instead of assertEquals() when the expected value is a literal; assertEquals() compares loosely (==)';
            $this->report($phpcsFile, $stackPtr, $message, 'LiteralExpected', [$this->getSuggestion($expected)]);
        } else if ($actual !== null) {
            $message = 'assertEquals() arguments are reversed: put the expected literal first and use %s';
            $this->report($phpcsFile, $stackPtr, $message, 'LiteralActual', [$this->getSuggestion($actual)]);
        }
    }

    /**
     * Reports an error in CiviCRM core, a warning elsewhere.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int                         $stackPtr  The position of the assertEquals token.
     * @param string                      $message   The message.
     * @param string                      $code      The violation code.
     * @param array<string>               $data      Replacements for the message.
     *
     * @return void
     */
    private function report(File $phpcsFile, $stackPtr, $message, $code, array $data)
    {
        if ($this->isCoreFile($phpcsFile->getFilename()) === true) {
            $phpcsFile->addError($message, $stackPtr, $code, $data);
        } else {
            $phpcsFile->addWarning($message, $stackPtr, $code, $data);
        }
    }

    /**
     * Splits the call's arguments into token ranges.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int                         $open      The opening parenthesis.
     *
     * @return array<array{int, int}> [start, end] token positions, without surrounding whitespace.
     */
    private function getArguments(File $phpcsFile, $open)
    {
        $tokens = $phpcsFile->getTokens();
        $close  = $tokens[$open]['parenthesis_closer'];
        $args   = [];
        $start  = ($open + 1);
        for ($i = ($open + 1); $i <= $close; $i++) {
            // Skip over nested parentheses, arrays and closures.
            if (isset($tokens[$i]['parenthesis_closer']) === true && $i !== $close && $tokens[$i]['code'] === T_OPEN_PARENTHESIS) {
                $i = $tokens[$i]['parenthesis_closer'];
                continue;
            }

            if (isset($tokens[$i]['bracket_closer']) === true && in_array($tokens[$i]['code'], [T_OPEN_SHORT_ARRAY, T_OPEN_SQUARE_BRACKET, T_OPEN_CURLY_BRACKET], true) === true) {
                $i = $tokens[$i]['bracket_closer'];
                continue;
            }

            if ($i === $close || $tokens[$i]['code'] === T_COMMA) {
                $first = $phpcsFile->findNext(Tokens::$emptyTokens, $start, $i, true);
                if ($first !== false) {
                    $last   = $phpcsFile->findPrevious(Tokens::$emptyTokens, ($i - 1), ($first - 1), true);
                    $args[] = [$first, $last];
                }

                $start = ($i + 1);
            }
        }

        return $args;
    }

    /**
     * Gets the kind of literal an argument is, if it is a single literal.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param array{int, int}             $range     The argument's [start, end] tokens.
     *
     * @return string|null One of 'string', 'int', 'float', 'true', 'false', 'null', 'constant', or NULL.
     */
    private function getLiteralKind(File $phpcsFile, array $range)
    {
        $tokens = $phpcsFile->getTokens();
        [$start, $end] = $range;

        // Ignore anything that isn't a plain value (e.g. comments inside the argument).
        $parts = [];
        for ($i = $start; $i <= $end; $i++) {
            if (isset(Tokens::$emptyTokens[$tokens[$i]['code']]) === false) {
                $parts[] = $i;
            }
        }

        // Negative numbers: "-" followed by a number.
        if (count($parts) === 2 && $tokens[$parts[0]]['code'] === T_MINUS) {
            array_shift($parts);
            if (in_array($tokens[$parts[0]]['code'], [T_LNUMBER, T_DNUMBER], true) === false) {
                return null;
            }
        }

        if (count($parts) === 1) {
            switch ($tokens[$parts[0]]['code']) {
            case T_CONSTANT_ENCAPSED_STRING:
                return 'string';
            case T_LNUMBER:
                return 'int';
            case T_DNUMBER:
                return 'float';
            case T_TRUE:
                return 'true';
            case T_FALSE:
                return 'false';
            case T_NULL:
                return 'null';
            }
        }

        // "Double quoted $strings" are a series of T_DOUBLE_QUOTED_STRING tokens.
        $allDoubleQuoted = ($parts !== []);
        foreach ($parts as $part) {
            if ($tokens[$part]['code'] !== T_DOUBLE_QUOTED_STRING) {
                $allDoubleQuoted = false;
                break;
            }
        }

        if ($allDoubleQuoted === true) {
            return 'string';
        }

        // Class constants: Foo::BAR, \Foo\Bar::BAZ, self::BAR, static::BAR (not Foo::class).
        // PHPCS 3 tokenizes a namespaced class name as T_NS_SEPARATOR/T_STRING tokens.
        $count = count($parts);
        if ($count >= 3
            && $tokens[$parts[($count - 2)]]['code'] === T_DOUBLE_COLON
            && $tokens[$parts[($count - 1)]]['code'] === T_STRING
            && strtolower($tokens[$parts[($count - 1)]]['content']) !== 'class'
        ) {
            $nameTokens = [T_STRING, T_NS_SEPARATOR, T_SELF, T_STATIC, T_PARENT];
            for ($i = 0; $i < ($count - 2); $i++) {
                if (in_array($tokens[$parts[$i]]['code'], $nameTokens, true) === false) {
                    return null;
                }
            }

            return 'constant';
        }

        return null;
    }

    /**
     * Gets the suggested replacement assertion for a kind of literal.
     *
     * @param string $kind The literal kind.
     *
     * @return string
     */
    private function getSuggestion($kind)
    {
        switch ($kind) {
        case 'true':
            return 'assertTrue()';
        case 'false':
            return 'assertFalse()';
        case 'null':
            return 'assertNull()';
        default:
            return 'assertSame()';
        }
    }

    /**
     * Whether a file is inside a CiviCRM core checkout (including core extensions).
     *
     * Core's root contains Civi.php and CRM/Core/Config.php.
     *
     * @param string $fileName The file path.
     *
     * @return bool
     */
    private function isCoreFile($fileName)
    {
        $dir     = dirname((string) realpath($fileName));
        $visited = [];
        $isCore  = false;
        while ($dir !== '' && $dir !== '.') {
            if (isset(self::$coreDirs[$dir]) === true) {
                $isCore = self::$coreDirs[$dir];
                break;
            }

            $visited[] = $dir;
            if (is_file($dir.'/Civi.php') === true && is_file($dir.'/CRM/Core/Config.php') === true) {
                $isCore = true;
                break;
            }

            $parent = dirname($dir);
            if ($parent === $dir) {
                break;
            }

            $dir = $parent;
        }

        foreach ($visited as $seen) {
            self::$coreDirs[$seen] = $isCore;
        }

        return $isCore;
    }

}

<?php

namespace CiviCRM\Sniffs\Functions;

use Drupal\Sniffs\Functions\DiscouragedFunctionsSniff as DrupalDiscouragedFunctionsSniff;
use PHP_CodeSniffer\Util\Tokens;

/**
 * Discourages debug and unsafe functions, while allowing a script to boot
 * CiviCRM with eval(`cv php:boot`).
 */
class DiscouragedFunctionsSniff extends DrupalDiscouragedFunctionsSniff {

    /**
     * Generates the error or warning for this sniff.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the forbidden function in the token array.
     * @param string $function The name of the forbidden function.
     * @param string $pattern The pattern used for the match.
     *
     * @return void
     */
    protected function addError($phpcsFile, $stackPtr, $function, $pattern = NULL)
    {
        if (strtolower($function) === 'eval') {
            $tokens = $phpcsFile->getTokens();
            $open = $phpcsFile->findNext(Tokens::$emptyTokens, ($stackPtr + 1), NULL, TRUE);
            $argument = $phpcsFile->getTokensAsString(($open + 1), ($tokens[$open]['parenthesis_closer'] - $open - 1));
            if (preg_match('/^\s*`cv php:boot( --?[\w=.-]+)*`\s*$/', $argument) === 1) {
                return;
            }
        }

        parent::addError($phpcsFile, $stackPtr, $function, $pattern);
    }

}

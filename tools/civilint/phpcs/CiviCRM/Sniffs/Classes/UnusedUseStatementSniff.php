<?php

namespace CiviCRM\Sniffs\Classes;

use Drupal\Sniffs\Classes\UnusedUseStatementSniff as DrupalUnusedUseStatementSniff;
use PHP_CodeSniffer\Files\File;
use PHP_CodeSniffer\Util\Tokens;

/**
 * Checks for "use" statements that are not needed in a file,
 * while allowing civix helper alias "use ... as E;".
 */
class UnusedUseStatementSniff extends DrupalUnusedUseStatementSniff {

    /**
     * Processes this test, when one of its tokens is encountered.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the current token in the stack passed in $tokens.
     *
     * @return void
     */
    public function process(File $phpcsFile, $stackPtr)
    {
        $tokens = $phpcsFile->getTokens();

        $semiColon = $phpcsFile->findEndOfStatement($stackPtr);
        if ($tokens[$semiColon]['code'] === T_SEMICOLON) {
            $classPtr = $phpcsFile->findPrevious(
                Tokens::$emptyTokens,
                ($semiColon - 1),
                NULL,
                TRUE
            );

            // Allow the civix "E" helper alias even if not called directly in the file
            if ($classPtr !== FALSE && $tokens[$classPtr]['code'] === T_STRING && $tokens[$classPtr]['content'] === 'E') {
                return;
            }
        }

        parent::process($phpcsFile, $stackPtr);
    }

}

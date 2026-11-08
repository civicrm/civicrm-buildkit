<?php

namespace CiviCRM\Sniffs\Schema;

use PHP_CodeSniffer\Files\File;
use PHP_CodeSniffer\Sniffs\Sniff;
use PHP_CodeSniffer\Util\Tokens;
use PHPCSUtils\Utils\TextStrings;

/**
 * Checks field declarations in *.entityType.php files for metadata that the
 * schema loader silently ignores.
 */
class EntityTypeFieldsSniff implements Sniff {

    /**
     * Input types as CiviCRM spells them.
     *
     * @var array<string>
     */
    private const INPUT_TYPES = [
      'CheckBox',
      'ChainSelect',
      'Color',
      'Date',
      'Email',
      'EntityRef',
      'File',
      'Number',
      'Password',
      'Radio',
      'RichTextEditor',
      'Select',
      'Select Date',
      'Text',
      'TextArea',
      'Toggle',
      'Url',
    ];

    /**
     * Returns the token types this sniff listens for.
     *
     * @return array<int>
     */
    public function register()
    {
        return [T_OPEN_TAG];
    }

    /**
     * Processes a file once.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $stackPtr The position of the open tag.
     *
     * @return int
     */
    public function process(File $phpcsFile, $stackPtr)
    {
        if (substr($phpcsFile->getFilename(), -strlen('.entityType.php')) !== '.entityType.php') {
            return $phpcsFile->numTokens;
        }

        $tokens = $phpcsFile->getTokens();
        for ($i = $stackPtr; $i < $phpcsFile->numTokens; $i++) {
            if ($tokens[$i]['code'] !== T_CONSTANT_ENCAPSED_STRING) {
                continue;
            }

            $arrow = $phpcsFile->findNext(Tokens::$emptyTokens, ($i + 1), NULL, TRUE);
            if ($arrow === FALSE || $tokens[$arrow]['code'] !== T_DOUBLE_ARROW) {
                continue;
            }

            $value = $phpcsFile->findNext(Tokens::$emptyTokens, ($arrow + 1), NULL, TRUE);
            $key = TextStrings::stripQuotes($tokens[$i]['content']);
            if ($key === 'input_type') {
                $this->checkInputType($phpcsFile, $value);
            }
elseif ($key === 'html' && $this->isLegacyHtml($phpcsFile, $value)) {
                $error = 'The "html" key has no effect in an entity type, use "input_type" and "input_attrs"';
                $phpcsFile->addError($error, $i, 'LegacyHtml');
}
        }

        return $phpcsFile->numTokens;
    }

    /**
     * Reports an input type that differs from a known one only in case.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $value The position of the value.
     *
     * @return void
     */
    private function checkInputType(File $phpcsFile, $value)
    {
        $tokens = $phpcsFile->getTokens();
        if ($tokens[$value]['code'] !== T_CONSTANT_ENCAPSED_STRING) {
            return;
        }

        $type = TextStrings::stripQuotes($tokens[$value]['content']);
        foreach (self::INPUT_TYPES as $known) {
            if ($type !== $known && strcasecmp($type, $known) === 0) {
                $error = 'Input type "%s" must be spelled "%s"';
                $phpcsFile->addError($error, $value, 'InputTypeCase', [$type, $known]);
            }
        }
    }

    /**
     * A field that happens to be named "html" declares its own sql_type.
     *
     * @param \PHP_CodeSniffer\Files\File $phpcsFile The file being scanned.
     * @param int $value The position of the value.
     *
     * @return bool
     */
    private function isLegacyHtml(File $phpcsFile, $value)
    {
        $tokens = $phpcsFile->getTokens();
        if ($tokens[$value]['code'] === T_OPEN_SHORT_ARRAY) {
            $closer = $tokens[$value]['bracket_closer'];
        }
elseif ($tokens[$value]['code'] === T_ARRAY) {
            $closer = $tokens[$tokens[$value]['parenthesis_opener']]['parenthesis_closer'];
}
else {
            return FALSE;
}

        $keys = [];
        for ($i = $value; $i < $closer; $i++) {
            if ($tokens[$i]['code'] === T_CONSTANT_ENCAPSED_STRING) {
                $keys[] = TextStrings::stripQuotes($tokens[$i]['content']);
            }
        }

        return in_array('type', $keys, TRUE) && !in_array('sql_type', $keys, TRUE);
    }

}

<?php

// Correct usage.
CRM_Core_DAO::executeQuery('SELECT id FROM t WHERE a = %1 AND b = %2', [1 => [$a, 'String'], 2 => [$b, 'Positive']]);
\CRM_Core_DAO::singleValueQuery('SELECT id FROM t WHERE a = %1 OR b = %1', [1 => [$a, 'Integer']]);
CRM_Core_DAO::executeQuery('SELECT 1 FROM t WHERE a = %1 AND b = %2', [1 => [$a, 'String'], [$b, 'Positive']]);
CRM_Core_DAO::executeQuery("SELECT id
  FROM t
  WHERE a = %1", [1 => [$a, 'String']]);
CRM_Core_DAO::composeQuery('SELECT %10', [10 => [$a, 'Integer']]);
CRM_Core_DAO::executeQuery('SELECT %0', [[$a, 'Integer']]);
CRM_Core_DAO::executeQuery('SELECT `%1` FROM civicrm_value_%2', [1 => [$a, 'MysqlColumnNameOrAlias'], 2 => [$b, 'Integer']]);

// Percent signs in SQL strings and modulo are no placeholders.
CRM_Core_DAO::executeQuery("SELECT id FROM t WHERE a LIKE '%5%' AND b = %1", [1 => [$a, 'String']]);
CRM_Core_DAO::executeQuery("SELECT DATE_FORMAT(d, '%Y') FROM t WHERE id%2 = %1", [1 => [$a, 'Integer']]);
CRM_Core_DAO::executeQuery("SELECT id FROM t WHERE a = '%1'", [1 => [$a, 'String', CRM_Core_DAO::QUERY_FORMAT_NO_QUOTES]]);
CRM_Core_DAO::executeQuery("SELECT id %2 FROM t WHERE a = %1", [1 => [$a, 'Integer']]);
CRM_Core_DAO::executeQuery("SELECT 1 /* a = %2 */ FROM t WHERE a = %1", [1 => [$a, 'Integer']]);
CRM_Core_DAO::executeQuery("SELECT 1 FROM t -- b = %2
  WHERE a = %1", [1 => [$a, 'Integer']]);

// Nothing to compare.
CRM_Core_DAO::executeQuery($sql, $params);
CRM_Core_DAO::executeQuery($sql, [1 => [$a, 'String']]);
CRM_Core_DAO::executeQuery($sql, [[$a, 'String']]);
CRM_Core_DAO::executeQuery("SELECT $column FROM t WHERE a = %2", [1 => [$a, 'String']]);
CRM_Core_DAO::executeQuery('SELECT ' . $column . ' WHERE a = %2', [1 => [$a, 'String']]);
CRM_Core_DAO::executeQuery('SELECT %1 %2', [1 => [$a, 'String'], $key => [$b, 'String']]);
CRM_Core_DAO::executeQuery('SELECT %1 %2', [$key => [$a, 'String'], [$b, 'String']]);
CRM_Core_DAO::executeQuery('SELECT %1');
CRM_Core_DAO::executeQuery('SELECT id', [], TRUE, 'CRM_Foo');
$this->executeQuery('SELECT %2', [1 => $a]);
Other::executeQuery('SELECT %2', [[$a, 'String']]);

// Parameters without a key.
CRM_Core_DAO::executeQuery('DELETE FROM t WHERE a = %1 AND id != %2', [
  [$a, 'String'],
  [$b, 'Positive'],
]);

// Placeholders without a parameter.
CRM_Core_DAO::executeQuery('SELECT %1, %3', [1 => [$a, 'String']]);
CRM_Core_DAO::singleValueQuery('SELECT %1', []);

CRM_Core_DAO::executeQuery("SELECT id
  FROM t
  WHERE a = %1 AND b = %2", [1 => [$a, 'String']]);

// Parameters without a placeholder.
CRM_Core_DAO::executeQuery('SELECT %1', [1 => [$a, 'String'], 2 => [$b, 'String']]);
CRM_Core_DAO::executeQuery('SELECT id FROM t WHERE a = %1 LIMIT %2', [1 => [$a, 'String']]);

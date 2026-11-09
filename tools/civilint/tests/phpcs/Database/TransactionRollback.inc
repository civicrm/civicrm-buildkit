<?php

function exceptionOnly() {
  $tx = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (CRM_Core_Exception $e) {
    $tx->rollback();
    throw $e;
  }
}

function namespacedClass() {
  $tx = new \CRM_Core_Transaction();
  try {
    save();
  }
  catch (\Exception $e) {
    $tx->rollback();
  }
}

function secondCatchOnly() {
  $tx = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (PEAR_Exception $e) {
    $tx->rollback();
  }
  catch (Exception $e) {
    $tx->rollback();
  }
}

function throwable() {
  $tx = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (Throwable $e) {
    $tx->rollback();
    throw $e;
  }
}

function union() {
  $tx = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (Exception | Error $e) {
    $tx->rollback();
  }
}

function siblingCatch() {
  $tx = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (CRM_Core_Exception $e) {
    $tx->rollback();
    return FALSE;
  }
  catch (\Throwable $e) {
    $tx->rollback();
    throw $e;
  }
}

function outerProtection() {
  $tx = new CRM_Core_Transaction();
  try {
    try {
      save();
    }
    catch (CRM_Core_Exception $e) {
      $tx->rollback();
      return FALSE;
    }
  }
  catch (Throwable $e) {
    $tx->rollback();
    throw $e;
  }
}

function finallyRollsBack() {
  $tx = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (Exception $e) {
    $tx->rollback();
  }
  finally {
    if (!$done) {
      $tx->rollback();
    }
  }
}

function otherConnection($db) {
  $other = new Doctrine\Connection();
  try {
    save();
  }
  catch (Exception $e) {
    $other->rollback();
    $db->rollback();
  }
}

function noRollback() {
  $tx = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (Exception $e) {
    log($e);
  }
}

function outerOnlyLogs() {
  $tx = new CRM_Core_Transaction();
  try {
    try {
      save();
    }
    catch (CRM_Core_Exception $e) {
      $tx->rollback();
    }
  }
  catch (Throwable $e) {
    log($e);
  }
}

function finallyRollsBackAnother() {
  $tx = new CRM_Core_Transaction();
  $other = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (Exception $e) {
    $tx->rollback();
  }
  finally {
    $other->rollback();
  }
}

function transactionIsNotFirst($db) {
  $tx = new CRM_Core_Transaction();
  try {
    save();
  }
  catch (Exception $e) {
    $db->rollback();
    $tx->rollback();
  }
}

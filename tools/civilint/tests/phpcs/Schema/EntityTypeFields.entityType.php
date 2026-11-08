<?php

return [
  'name' => 'Foo',
  'getFields' => fn() => [
    'id' => ['sql_type' => 'int unsigned', 'input_type' => 'Number'],
    'date' => ['sql_type' => 'datetime', 'input_type' => 'Select Date', 'input_attrs' => ['format_type' => 'activityDateTime', 'formatType' => 'searchDate']],
    'custom' => ['sql_type' => 'text', 'input_type' => 'MyExtensionWidget'],
    'none' => ['sql_type' => 'text', 'input_type' => NULL],
    'html' => ['sql_type' => 'text', 'title' => 'Body', 'input_type' => 'RichTextEditor'],
    'flag' => ['sql_type' => 'boolean', 'input_type' => 'Checkbox'],
    'kind' => ['sql_type' => 'int', 'input_type' => 'select'],
    'when' => ['sql_type' => 'datetime', 'input_type' => 'Select date'],
    'old' => [
      'sql_type' => 'datetime',
      'html' => [
        'type' => 'Select Date',
        'formatType' => 'activityDateTime',
      ],
    ],
  ],
];

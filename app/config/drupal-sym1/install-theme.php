<?php

// Enable blocks
db_query("update block set region='sidebar_first' where theme='bartik' and module='user' and delta='login'");
db_query("update block set region='sidebar_first' where theme='bartik' and module='system' and delta='navigation'");

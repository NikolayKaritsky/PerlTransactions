# PerlTransactions
Модуль для реализации транзакций в perl в конкурентной среде


ТЗ: 
"Напишите класс/модуль для реализации транзакций в perl в конкурентной среде из нескольких процессов,
например, чтобы можно было откатить изменения сделанные несколькими функциями или сохранить 
эти изменения пачкой, учитывая одновременный доступ из нескольких процессов.
Задача не про БД а про атомарные операции."

---------------------------
Модуль transactions.pm.

Функции:

addTransaction - Добавление транзакции в очередь (аргументы: четное количество элементов; четные элементы - ссылка на переменную/элемент массива; нечетные - ссылка на значение)

commitTransactions - Применение транзакций (без аргументов применяются все транзакции, с аргументом N - N первых.)

rollbackTransactions - Откат транзакций (без аргументов откатываются все транзакции, с аргументом N - N последних.)

getTransactionsQueue - Получить очередь транзакций (возвращает список timestamp'ов создания транзакций в очереди)

getBeforeStates - Получить очередь сохраненных состояний после проведенных транзакций (возвращает список timestamp'ов проведения транзакций)

Дополнительные настройки:

$showDebug=0; # Если 1, вывод отладочной информации

$errorProbability=0; # Процент вероятности ошибки операции (для тестирования); при ошибке в операции вся транзакция отклоняется

$addTransactionDelay = 0; # Если > 0, задержка в секундах при добавлении транзакции (для тестирования)

$commitTransactionDelay = 0; # Если > 0, задержка в секундах при применении транзакций (для тестирования)

$rollbackTransactionDelay = 0; # Если > 0, задержка в секундах при откате транзакций (для тестирования)

---------------------------
main.pl - Примеры работы с модулем

#!/usr/bin/perl
use strict;
use warnings;
use threads;

use transactions;

sub queuedTransactionsPrint # Печать списка 
                            # транзакций в очереди (номер, время создания) или
                            # состояний до транзакций (номер, время проведения транзакции)
{
    my ($i, $results) = (0, '');
    foreach (@_)
    {
        my $created=$_; $i++;
        $results .= sprintf(" %5d | %s \n", $i, scalar localtime $_);
    }
    $results = $i ? '_' x (34)."\n".$results."\n" : "empty list.\n\n";
    print $results;
}

my @arr : shared = ('qqq', 'www', 'eee', 'rrrr'); # Тестовый массив
my @arr2 : shared = ('aaa2', 'sss2', 'ddd2','ffff2'); # Тестовый массив 2
my $var : shared='Strawberry'; # Тестовая переменная
my $var2 : shared=42; # Тестовая переменная 2

my $testingTransactions = Thread::Queue->new();    # Тестовые транзакции (пары: ссылка на переменную, ссылка на значение/другую переменную )
$testingTransactions->enqueue([\$var, \'Cherry']);
$testingTransactions->enqueue([\$var, \60, \$var2, \41, \$arr[2], \'qwerty']);
$testingTransactions->enqueue([\$var, \70]);
$testingTransactions->enqueue([\$var, \80]);
$testingTransactions->enqueue([\$var, \90]);
$testingTransactions->enqueue([\$var, \100]);

my $checkStateTpl = " \@arr1: %-35s \@arr2: %-35s \$var: %-15s \$var2: %-10s \n"; # Шаблон для вывода тестовых массивов и переменных
printf "\nInitial state of arrays and variables:\n".$checkStateTpl, join(' | ', @arr), join(' | ', @arr2), $var, $var2; # Изначальное состояние

my @threads;

for my $i (1..3) { # Тестируем добавление транзакций в очередь потоками
    push @threads, threads->create(sub{
        while (my $data=$testingTransactions->extract()) {
            addTransaction(@$data);
        }
    }
    );

}
foreach my $thread (@threads) {
    $thread->join();
}

print "\nTransactions queue:\n"; 
queuedTransactionsPrint(getTransactionsQueue); # Состояние очереди транзакций 
              
for my $i (1..3) { # Тестируем применение транзакций потоками
    push @threads, threads->create(sub{
        commitTransactions(1); # например, по одной в каждом потоке
        printf "\nArrays and variables after committing transaction:\n".$checkStateTpl, join(' | ', @arr), join(' | ', @arr2), $var, $var2; 
			# Массивы, переменные после применения транзакции
    }
    );
}

foreach my $thread (@threads[3..5]) {
    $thread->join();
}

commitTransactions; # Применяем все остальные транзакции
printf "\nArrays and variables after committing all transactions:\n".$checkStateTpl, join(' | ', @arr), join(' | ', @arr2), $var, $var2; # Массивы, переменные после применения транзакции

print "\nTransactions queue:\n";
queuedTransactionsPrint(getTransactionsQueue); # Очередь теперь пуста
print "States before transactions:\n";
queuedTransactionsPrint(getBeforeStates); # Зато есть очередь состояний до применения транзакций

rollbackTransactions(1); # Откатываем последнюю транзакцию
printf "\nRollBack 1 transaction\n".$checkStateTpl, join(' | ', @arr), join(' | ', @arr2), $var, $var2;
rollbackTransactions; # Откатываем все остальные транзакции
printf "\nRollBack all transactions\n".$checkStateTpl, join(' | ', @arr), join(' | ', @arr2), $var, $var2;


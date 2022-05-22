package transactions;
require Exporter;
use Thread::Queue;

@ISA = qw(Exporter);
@EXPORT = qw(test addTransaction commitTransactions rollbackTransactions getTransactionsQueue getBeforeStates);

my $transactionsQueue = Thread::Queue->new();    # Очередь транзакций
my $beforeStates = Thread::Queue->new();    # Очередь состояний до применения транзакций

my $showDebug=0; # Если 1, вывод отладочной информации
my $errorProbability=0; # Процент вероятности ошибки операции (для тестирования)
my $addTransactionDelay = 0; # Если > 0, задержка в секундах при добавлении транзакции (для тестирования)
my $commitTransactionDelay = 0; # Если > 0, задержка в секундах при применении транзакций (для тестирования)
my $rollbackTransactionDelay = 0; # Если > 0, задержка в секундах при откате транзакций (для тестирования)


sub addTransaction # Добавление транзакции в очередь
{
    if (@_)
    {
        print localtime.": Thread ",threads->tid," going to add transaction in queue\n" if $showDebug;
        lock ($transactionsQueue);
        sleep $addTransactionDelay if ($addTransactionDelay);
        $transactionsQueue->enqueue([time, [@_]]); # время создания, содержание 
                                                   # (чётные элементы - ссылки на переменные, нечётные - _ссылки_ на значения)
        print localtime.": Thread ", threads->tid, " added transaction in queue. Queue size = ".$transactionsQueue->pending()."\n" if $showDebug;
    }
}
sub commitTransactions # Без аргумента применяем все транзакции, с аргументом N - N первых
{
    lock ($transactionsQueue);
    lock ($beforeStates);
    sleep $commitTransactionDelay if ($commitTransactionDelay);
    my $transactions = ($_[0]) ? ($_[0]) : $transactionsQueue->pending();
    while ($transactions--)
    {
        last unless (my $data=$transactionsQueue->extract());
        my @content = @{$$data[1]};
        my $operations = @content / 2; # Действий в транзакции
        print localtime.": Thread ",threads->tid," going to commit transaction in queue (operations: $operations)\n" if $showDebug;

        my (@vars, @values, @before_values);
        my $transactionOk = 1; # Флаг на успешность транзакции
        my @beforeState = ();
        while ($operations--)
        {
            my ($var, $value) = (shift @content, shift @content);
            push @vars, $var;
            push @before_values, $$var;
            unless (($$var = $$value) == $$value and $errorProbability < rand(100)) # Если что-то пошло не так, транзакция не применяется 
                    # Хотя, что здесь могло пойти не так? Но по условиям операция атомарная, должна пройти полностью, иначе идем в откат. 
                    # $errorProbability = процент вероятности ошибки
            {                                      
                $transactionOk = 0; last;          
            }
        }
        my $operationsCount = @vars;
        if ($transactionOk) # Транзакция успешна
        {
            while ($operationsCount--)
            {
                push @beforeState, shift @vars;
                push @beforeState, shift @before_values;
            }
            $beforeStates->enqueue([time, [@beforeState]]); # добавляем состояние до транзакции:
                                                            # время проведения транзакции, состояние переменных до её проведения
                                                            # (чётные элементы - ссылки на переменные, нечётные - _значения_)

            print localtime.": Thread ",threads->tid," successfully commited transaction, queue = ".$transactionsQueue->pending()."\n" if $showDebug;
        }
        else # Откатываем попытку транзакции
        {
            while ($operationsCount--)
            {
                my ($var, $value) = (shift @vars, shift @before_values);
                $$var = $value;
            }
            print localtime.": Error! Thread ",threads->tid," has not commited transaction, queue = ".$transactionsQueue->pending()."\n" if $showDebug;
        }

    }
}
sub rollbackTransactions # Без аргумента откатываем все транзакции, с аргументом N - N последних
{
    lock ($beforeStates);
    sleep $rollbackTransactionDelay if ($rollbackTransactionDelay);
    my $transactions = ($_[0]) ? ($_[0]) : $beforeStates->pending();

    while ($transactions--)
    {
        last unless (my $data=$beforeStates->extract(-1));
        my @content = @{$$data[1]}; # Содержание отката
        my $operations = @content / 2; # Действий в откате
        print localtime.": Thread ",threads->tid," going to rollback transaction (operations: $operations)\n" if $showDebug;

        while ($operations--)
        {
            my ($var, $value) = (shift @content, shift @content);
            $$var = $value # Откат переменной к значению
        }
    }

}
sub getTransactionsQueue # Возвращает список timestamp'ов создания транзакций в очереди
{
    my @list = map {$transactionsQueue->peek($_)->[0]} (0..$transactionsQueue->pending()-1);
    return @list;
}
sub getBeforeStates # Возвращает список timestamp'ов проведения транзакций
{
    my @list = map {$beforeStates->peek(-$_)->[0]} (1..$beforeStates->pending());
    return @list;
}

1
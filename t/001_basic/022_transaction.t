use t::Utils;
use Test::More;
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'do basic transaction' => sub {
    $db->txn_begin;
    my $row = $db->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 1;
    is $row->name, 'perl';
    $db->txn_commit;

    is +$db->single('mock_basic',{id => 1})->name, 'perl';
};
 
subtest 'do rollback' => sub {
    $db->txn_begin;
    my $row = $db->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    $db->txn_rollback;
    
    ok not +$db->single('mock_basic',{id => 2});
};
 
subtest 'do commit' => sub {
    $db->txn_begin;
    my $row = $db->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    $db->txn_commit;
 
    ok +$db->single('mock_basic',{id => 2});
};

subtest 'error occurred in transaction' => sub {

    eval {
        local $SIG{__WARN__} = sub {};
        my $txn = $db->txn_scope;
        $db->{dbh} = undef;
        $db->dbh;
    };
    my $e = $@;
    like $e, qr/Detected disconnected database during a transaction. Refusing to proceed at/;
};
 
done_testing;

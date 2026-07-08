use Cwd qw(abs_path);
use File::Basename qw(dirname);

my $repo_root = dirname(abs_path(__FILE__));
my $output_dir = "${repo_root}/output";

$out_dir = $output_dir;
$aux_dir = $output_dir;

$ENV{'TEXINPUTS'} = join(':', 'src//', $ENV{'TEXINPUTS'} // '');
$ENV{'BIBINPUTS'} = join(':', 'src//', $ENV{'BIBINPUTS'} // '');
$ENV{'BSTINPUTS'} = join(':', 'src//', $ENV{'BSTINPUTS'} // '');

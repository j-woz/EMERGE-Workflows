
import io;
import files;
import random;

seed = float2int(random() * 100);
printf("seed: %i", seed);

tmp      = "/tmp/wozniak/work";
ensemble = "/global/cfs/cdirs/m3623/wozniak/1k_bay";

seed_dir = "%s/seed%i" % (ensemble, seed);
work_dir = "%s/seed%i" % (tmp,      seed);

printf("seed_dir: " + seed_dir);
printf("work_dir: " + work_dir);

file plts[] = glob(seed_dir + "/plt*.h5");
printf("plts: %i", size(plts));

foreach plt in plts
{
  fn = basename(plt);
  file dest<work_dir/fn> = plt;
}

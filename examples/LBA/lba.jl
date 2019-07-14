using StanSample
using CmdStan: CMDSTAN_HOME, set_cmdstan_home!

cd(@__DIR__)

LBA = "
functions{

     real lba_pdf(real t, real b, real A, real v, real s){
          //PDF of the LBA model

          real b_A_tv_ts;
          real b_tv_ts;
          real term_1;
          real term_2;
          real term_3;
          real term_4;
          real pdf;

          b_A_tv_ts = (b - A - t*v)/(t*s);
          b_tv_ts = (b - t*v)/(t*s);
          term_1 = v*Phi(b_A_tv_ts);
          term_2 = s*exp(normal_lpdf(b_A_tv_ts|0,1));
          term_3 = v*Phi(b_tv_ts);
          term_4 = s*exp(normal_lpdf(b_tv_ts|0,1));
          pdf = (1/A)*(-term_1 + term_2 + term_3 - term_4);

          return pdf;
     }

     real lba_cdf(real t, real b, real A, real v, real s){
          //CDF of the LBA model

          real b_A_tv;
          real b_tv;
          real ts;
          real term_1;
          real term_2;
          real term_3;
          real term_4;
          real cdf;

          b_A_tv = b - A - t*v;
          b_tv = b - t*v;
          ts = t*s;
          term_1 = b_A_tv/A * Phi(b_A_tv/ts);
          term_2 = b_tv/A   * Phi(b_tv/ts);
          term_3 = ts/A     * exp(normal_lpdf(b_A_tv/ts|0,1));
          term_4 = ts/A     * exp(normal_lpdf(b_tv/ts|0,1));
          cdf = 1 + term_1 - term_2 + term_3 - term_4;

          return cdf;

     }

     real lba_lpdf(matrix RT, real k, real A, vector v, real s, real tau){

          real t;
          real b;
          real cdf;
          real pdf;
          vector[rows(RT)] prob;
          real out;
          real prob_neg;

          b = A + k;
          for (i in 1:rows(RT)){
               t = RT[i,1] - tau;
               if(t > 0){
                    cdf = 1;

                    for(j in 1:num_elements(v)){
                         if(RT[i,2] == j){
                              pdf = lba_pdf(t, b, A, v[j], s);
                         }else{
                              cdf = (1-lba_cdf(t, b, A, v[j], s)) * cdf;
                         }
                    }
                    prob_neg = 1;
                    for(j in 1:num_elements(v)){
                         prob_neg = Phi(-v[j]/s) * prob_neg;
                    }
                    prob[i] = pdf*cdf;
                    prob[i] = prob[i]/(1-prob_neg);
                    if(prob[i] < 1e-10){
                         prob[i] = 1e-10;
                    }

               }else{
                    prob[i] = 1e-10;
               }
          }
          out = sum(log(prob));
          return out;
     }
}

data{
     int N;
     int Nc;
     vector[N] rt;
     vector[N] choice;
}

parameters {
     real<lower=0> k;
     real<lower=0> A;
     real<lower=0> tau;
     vector<lower=0>[Nc] v;
}

model {
     real s;
     matrix[N,2] RT;
     s=1;
     RT[:,1] = rt;
     RT[:,2] = choice;
     k ~ normal(.5,1)T[0,];
     A ~ normal(.5,1)T[0,];
     tau ~ normal(.5,.5)T[0,];
     for(n in 1:Nc){
          v[n] ~ normal(2,1)T[0,];
     }
     RT ~ lba(k,A,v,s,tau);
}
";

LBA_data = (Nc = 3, N = 200, rt = [
  0.5172563185035218, 0.8128454208564759, 0.5287927016034656, 0.6052793579150275, 
  0.723151190095471, 0.7460198463976369, 0.45431036513273687, 0.9057048332956246,
  0.5706689553572384, 0.8084971308318065, 0.619517451443632, 0.5983122383151855,
  0.6435242973178197, 1.1321032066600665, 0.6647108084245479, 0.49330145136481923,
  0.6149854662216923,0.6511213339085504,0.5568235912567999,0.6044452252118269,
  0.49566438865268736,0.6279681980301477,0.8117378786097601,0.6172740150854072,
  0.4948989304604639,0.7675369226331317,0.46353371786271824,0.645651483256734,
  0.8963288513778418,0.7146600910671628,0.5408767499701641,0.9650536609042444,
  0.5578421275764064,0.5795453896321787,0.6057684089639942,1.5631874975130597,
  0.629808141744541,1.022421056465441,0.6996055605296965,0.5106721416624329,
  0.5917700094202267,0.7091020907029699,0.6119760415323193,0.7014004524524569,
  0.6011453541927583,0.6164693504868568,0.5663668177526784,0.8931165405119605,
  0.5635466158342433,0.5220944220791173,0.5495697677181935,0.462466932393734,
  0.5415455854737724,0.6369646691761369,0.6809963375645367,0.552897656359747,
  0.6188821565306044,0.5030067555354056,0.6057070496540626,0.6072234852359264,
  0.5030390039084438,0.7605180052353402,0.8753965811982178,0.7100046668672728,
  0.6786320746373478,0.5204538842008222,0.5344689749468778,0.5434745621403249,
  0.5981603048774546,0.7328587072762123,0.644715791453861,0.6243597629188848,
  1.3855200658432651,0.48084093691859586,0.7689218001385749,0.7695036016681377,
  1.0869514748343296,0.7959213856975516,0.5348614356661059,0.4936584374011437,
  0.7096991230294177,0.5243555890435926,0.6320511613857858,0.5769494290780035,
  0.7307312216352477,0.5158226425292626,0.6857721952574352,0.5311504860506873,
  0.6877066575282882,0.5670345547148583,0.7249837316204284,0.7040416637968604,
  0.5454428582470049,0.5977294133097858,0.48001836194920766,0.5152010316305199,
  0.5819798987992713,0.788609952938505,0.5176348868183556,0.6683149041712193,
  0.6896216443937007,0.554724513161415,0.6300558955376948,0.6229862854781085,
  0.54458864060411,0.6312182280659482,0.5528622430791532,0.5677220820816027,
  0.6027445523827388,0.5023157798139705,0.6977735437611517,0.809475166191995,
  0.5704580867030262,0.5046427158534664,0.5255592626852288,0.6143857329367953,
  0.6178402270963708,0.5631464929269593,0.5965224748140201,0.7298831748338575,
  0.6946700553045693,0.4820532443228644,0.6736483636790365,0.6737106523311083,
  0.9232974483628132,0.7354470000550888,0.6726116531295407,0.5883287005892515,
  0.6160263479549937,0.5573678777576276,0.7625656142155866,0.5292714975831675,
  0.7246075325766295,0.7708827544279314,0.5336499540403102,0.8051382314453717,
  0.6442494256307568,0.9334582322639116,0.9461083952852346,0.6196330941672238,
  0.5586124687600272,0.5566129176765593,0.7904878901502628,0.7479393473413253,
  0.6574586477816032,0.4944981578764378,0.6510666622321069,0.6166906369729925,
  0.5000436387722222,0.4752189615622799,0.5959538562155668,0.6938059053886498,
  0.6438274327143417,0.5589433865365045,0.5846831738823322,0.6314707748237262,
  0.5140271877113509,0.49346493970846383,0.6515051208839449,0.8294415751644921,
  2.0321926771647276,0.49412525362775855,0.5303283741433148,0.8523027635055367,
  0.5414768731824661,0.4695826111771622,0.48833888190741115,0.7167178014989934,
  1.1408781345289776,0.7140074385674222,0.6272348029864163,0.48052613023089863,
  0.6281778536199709,0.6012504548489284,0.5462307192768121,0.6239689876094862,
  0.8432350862861097,0.7694134803246382,0.5391600922718652,0.63566692258107,
  0.871898665375137,0.5966805648137725,0.5756731591390922,0.9990694566686539,
  0.5242361805544791,0.4813390113561128,0.5665089258206126,0.5094476254864568,
  0.553923456556689,0.6379083181936438,0.5265558116761913,0.6318610211301654,
  0.4840139865984098,0.567837742224435,1.1478087390790883,0.6157830093722181,
  0.4597544454463623,0.7692541965561321,0.5552938695617227,0.5893517515699693],
  choice = [1,2,3,3,3,2,1,3,3,3,2,2,1,3,3,3,1,3,1,3,3,2,3,3,3,3,3,2,1,2,3,2,2,3,2,3,2,3,3,3,2,3,2,2,1,
  3,2,3,3,3,1,2,2,3,3,2,2,3,3,2,1,2,1,3,1,3,3,2,2,2,2,2,2,3,1,3,1,1,2,2,3,3,3,3,3,3,2,3,3,3,1,2,3,2,2,
  3,2,1,3,3,3,3,3,1,3,3,3,3,2,3,2,2,3,2,3,2,2,3,3,2,3,3,3,2,2,3,3,3,2,2,1,3,1,3,1,3,3,1,1,3,1,3,1,1,2,
  2,1,2,3,2,3,2,2,1,1,3,2,3,2,3,3,1,1,3,2,2,3,3,2,2,1,2,3,1,1,3,2,3,2,3,3,3,3,2,2,3,3,3,3,3,3,2,2,2,2,2,3,3,2,3]
);

# First 2 runs are using the standard 2.19.1 version of cmdstan

# This run tests passing a data file name as data in the stan_sample() call

set_cmdstan_home!(CMDSTAN_HOME)
@time stanmodel = SampleModel("LBA", LBA; 
  method = StanSample.Sample(adapt = StanSample.Adapt(delta = 0.95)));

(sample_file, log_file) = stan_sample(stanmodel; data="LBA.R", n_chains=4)

sdf = StanSample.read_summary(stanmodel)
display(sdf)

sfile = stanmodel.output_base*"_summary.csv"
run(`awk 'NR > 5 && NR < 15 {print $0}' $(sfile)`)
run(`awk 'NR > 14 && NR < 115 {sum += $8} END {print sum}' $(sfile)`)
run(`awk 'NR > 14 && NR < 115 {sum += $9} END {print sum}' $(sfile)`)

# This run generates the R dump files

CMDSTAN_HOME_BOB="/Users/rob/Projects/StanSupport/cmdstan_bob"
isdir(CMDSTAN_HOME_BOB) && set_cmdstan_home!(CMDSTAN_HOME_BOB)
@time stanmodel1 = SampleModel("LBA", LBA;
  method = StanSample.Sample(adapt = StanSample.Adapt(delta = 0.95)));
(sample_file1, log_file1) = stan_sample(stanmodel1; data=LBA_data, n_chains=4)

sdf1 = StanSample.read_summary(stanmodel1)
display(sdf1)

sfile = stanmodel1.output_base*"_summary.csv"
run(`awk 'NR > 5 && NR < 15 {print $0}' $(sfile)`)
run(`awk 'NR > 14 && NR < 115 {sum += $8} END {print sum}' $(sfile)`)
run(`awk 'NR > 14 && NR < 115 {sum += $9} END {print sum}' $(sfile)`)

# Switch to a different build of cmdstan

CMDSTAN_HOME_MICHAEL="/Users/rob/Projects/StanSupport/cmdstan_michael"
isdir(CMDSTAN_HOME_MICHAEL) && set_cmdstan_home!(CMDSTAN_HOME_MICHAEL)
stanmodel2 = SampleModel("LBA", LBA;
  method = StanSample.Sample(adapt = StanSample.Adapt(delta = 0.95)));

(sample2_file, log_file2) = stan_sample(stanmodel2; data=LBA_data, n_chains=4)

sdf2 = StanSample.read_summary(stanmodel2)
display(sdf2)

sfile = stanmodel2.output_base*"_summary.csv"
run(`awk 'NR > 5 && NR < 15 {print $0}' $(sfile)`)
run(`awk 'NR > 14 && NR < 115 {sum += $8} END {print sum}' $(sfile)`)
run(`awk 'NR > 14 && NR < 115 {sum += $9} END {print sum}' $(sfile)`)


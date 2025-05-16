{smcl}
{* 12jul2012}{...}
{hline}
help for {hi:gam}{right:Patrick Royston, Gareth Ambler}
{hline}

{title:Generalized additive models}

{p 8 17 2}
{cmd:gam}
[{it:yvar}]
{it:xvars}
[{it:covars}]
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{it:weight}]
[{cmd:,}
{cmdab:bt:olerance(}{it:#}{cmd:)}
{cmdab:de:ad(}{it:deadvar}{cmd:)}
{cmd:df(}{it:dflist}{cmd:)}
{cmdab:f:amily(}{it:familyname}{cmd:)}
{cmdab:l:ink(}{it:linkname}{cmd:)}
{cmdab:lt:olerance(}{it:#}{cmd:)}
{cmdab:nome:rge}
{cmdab:mi:ssing(}{cmd:missing_code}{cmd:)}
{cmdab:nor:efresh}
]

{pstd}
where

{p 8 8 2}
{it:familyname} is one of
{cmdab:gau:ssian},
{cmdab:b:inomial},
{cmdab:p:oisson},
{cmdab:gam:ma},
{cmdab:c:ox},
{cmdab:s:tcox};

{p 8 8 2}
{it:linkname} is one of
{cmdab:ide:ntity},
{cmd:log},
{cmdab:l:ogit},
{cmdab:inv:erse},
{cmdab:c:ox}.

{pstd}
Note that {it:yvar} and {cmd:dead()} are not allowed with
{cmd:family(stcox)}. {it:yvar} is required
in all other cases, and {cmd:dead()} is required with {cmd:family(cox)}.

{pstd}
{cmd:gam} without arguments or options redisplays results from the most recent
command.

{pstd}
Weight-types {cmd:aweight}, {cmd:fweight} and {cmd:iweight} are allowed.


{title:Description}

{pstd}
{cmd:gam} fits a generalized or proportional hazards additive model (GAM) for {it:yvar}
as a function of {it:xvars} by mazimizing a penalized log likelihood function. Each
component of the resulting estimated function of {it:xvars} is a cubic smoothing
spline. The smoothness of each component function is determined by the
'equivalent degrees of freedom' of the corresponding xvar, specified in the
{cmd:df()} option. 

{pstd}
See Hastie and Tibshirani (1990) for full details and examples of GAMs.
See also {helpb gamplot} for plotting the resulting function(s).

{pstd}
{ul:{hi:Important: Operating system compatibility}}

{pstd}
The current version of {cmd:gam} runs on all known versions
of the Windows operating system up to 7 (Windows 95, 98, ME, 2000, XP, Vista,
7). We  have not tested it with Windows 8, but it should work. {cmd:gam}
versions earlier than 2.0.3 (17 May 2002) may appear to run on Windows 2000
or later, but are not guaranteed to give correct results, and may fail
with puzzling error messages. As far as we know, {cmd:gam} will NOT run on any
native Apple Mac operating system. It should run on a Mac under Windows
emulation, but we have not tested it.

{pstd}
{ul:{hi:Important: Installation notes}}

{pstd}
When installing a user-written program such as {cmd:gam}, it seems difficult
to tell Stata to place files other than .ado, .hlp and .sthlp in the usual
"stbplus" subfolder, typically c:\ado\stbplus/ on a Windows computer.

{pstd}
You can achieve a "clean" installation of the latest version of
{cmd:gam} as follows:

{phang}0.  If Stata is open, save your work and close Stata.

{phang}1.  Delete files gam*.ado and gam*.hlp (or gam*.sthlp, depending on which
version of {cmd:gam} you have currently) from wherever you have them.

{phang}2.  Restart Stata and install the current gam from Royston's UCL webpage
using the command
{cmd:net from http://www.homepages.ucl.ac.uk/~ucakjpr/stata/}.
 
{phang}3.  Click on {cmd:gam} and follow the links to install {cmd:gam}.
Make sure you then also press "click here to get" on gam.exe.

{phang}4.  Step 2 installs the ado and sthlp files in c:\stbplus\g\.
The file gam.exe is copied to your Stata current working directory.
In Windows, now copy gam.exe from your Stata current working directory
to c:\stbplus\g\.

{phang}5.  You should now have all the gam files in the right place and are
ready to continue your work.


{title:Options}

{phang}
{cmd:df(}{it:dflist}{cmd:)} sets up the equivalent degrees of freedom
(edf) for each predictor. The edf may be fractional. An
item in {it:dflist} may be either {it:#} or {it:varlist}{cmd::}{it:#}.
Items are separated by commas. {it:varlist} is specified in the usual way
for variables. With the first type of item, the edf for all predictors
are taken to be {it:#}. With the second type of item, all members of {it:varlist}
(which must be a subset of {it:xvars}) have {it:#} edf.
If an item of the second type follows one of the first type, the later
{it:#} overrides the earlier {it:#} for each variable in {it:varlist}.

        Example: {cmd:df(3)}.                      [All variables have 3 edf.]

        Example: {cmd:df(weight displ:4, mpg:2)}.  [{cmd:weight} and {cmd:displ} have 4 edf,
                                              {cmd:mpg} has 2 edf, all other variables
                                              have the default of 1 edf.]

        Example: {cmd:df(3, weight displ:4)}.      [{cmd:weight} and {cmd:displ} have 4 edf,
                                              all other variables have 3 edf.]
    
        Example: {cmd:df(weight displ:4, 3)}.      [All variables have 3 edf, since
                                              the final {it:#} overrides the earlier.]
    
{pmore}
Default: 1 df for all predictors.

{phang}
{cmd:family(}{it:familyname}{cmd:)} specifies the distribution of
{it:yvar}; {cmd:family(gaussian)} is the default.

{phang}
{cmd:link(}{it:linkname}{cmd:)} specifies the link function.
The default for each family are the canonical links:
{cmd:identity} for {cmd:family(gauss)},
{cmd:logit} for {cmd:family(binom)},
{cmd:log} for {cmd:family(poisson)},
{cmd:inverse} for {cmd:family(gamma)},
and by convention, {cmd:cox} for {cmd:family(cox)} and {cmd:family(stcox)}.

{phang}
{cmd:nomerge} prevents fitted values, residuals etc resulting from the GAM fit being
    merged with the data. This option is useful when you are only interested
    in summary statistics from the fit, as it reduces processing time somewhat.

{phang}
{cmd:norefresh} prevents the data being saved to files {cmd:$.dat} and {cmd:$.inx}. This
    option is useful when you have already performed a fit with a given dataset
    and don't wish the computer to spend time recreating {cmd:$.dat} and {cmd:$.inx}.

{phang}
{cmd:missing(}{it:#}{cmd:)} defines the missing value code seen by 
GAMFIT to be {it:#}, which must be a number. Default {it:#} is 9999.

{phang}
{cmd:dead(}{it:deadvar}{cmd:)} only applies to Cox regression. 
{it:deadvar} is the censoring variable (0 for censored, 1 for 'dead').

{phang}
{cmd:ltolerance(}{it:#}{cmd:)} sets the tolerance for convergence of the local scoring
algorithm to {it:#}. Default {it:#} is 0.001.

{phang}
{cmd:btolerance(}{it:#}{cmd:)} sets the tolerance for convergence of the backfitting
algorithm to {it:#}. Default {it:#} is 0.0005.


{title:Remarks}

{pstd}
{cmd:gam} creates the necessary input files for use by a version of the Fortran
program GAMFIT, written by Trevor Hastie & Robert Tibshirani, and runs the
program, here called {cmd:gam.exe}. The files are stored in the current Stata data
directory.

{pstd}
{cmd:gam} omits any records containing missing values of {it:yvar}, {it:xvars} and (for
{cmd:family(cox)} {it:deadvar}. Also, it sorts the data in the order {it:yvar} {it:xvars}.

{pstd}
Note that predictors are mean-centered before analysis. As a result, the
estimate and standard error of the intercept will differ from those produced
using Stata commands such as {cmd:glm}, {cmd:logit} and {cmd:regress}.

{pstd}
For each predictor with df > 1, {cmd:gam} reports a statistic called the 'Gain',
which is the difference in normalized deviance between the GAM and a model with
a linear term for that predictor. A large gain indicates a lot of nonlinearity,
at least as regards statistical significance. The associated P-value is based
on a chi-square approximation to the distribution of the gain if the true
marginal relationship between that term and {it:yvar} was linear. It should be
regarded only as impressionistic as the statistical inference is approximate.

{pstd}
Note that the software may not provide exactly the number of df that was asked
for. With cubic smoothing spline models, the degrees of freedom is estimated
from the data. The achieved df is shown in the table of results.

{pstd}
Models with {cmd:family(poisson)} need to be specified by the following technique:

{pmore}
1. Generate event-rate = (number of events)/exposure (ie. person-time at risk)

{pmore}
2. Fit the model using {cmd:gam} on event-rate with
{cmd:iweight} = {it:exposure}, and {cmd:family(poisson)}.

{pstd}
To fit models with {cmd:family(stcox)}, the data must be {cmd:stset} before analysis.
Only the most basic type of proportional hazards model is supported by {cmd:gam}.

{pstd}
For Gaussian models and gamma models, the deviance is scaled (i.e. is a 
transformation of the residual sum of squares for Gaussian models).


{pstd}
{ul:{hi:New variables created}}

{pstd}
{cmd:gam} creates a new variable {cmd:GAM_mu} containing the fitted values on the
scale of the response variable. For {it:xvars}, {cmd:gam} creates three other 
variables, as follows:

        {cmd:s_}{it:xvarname}  smooth for {it:xvarname}
        {cmd:e_}{it:xvarname}  pointwise standard errors of smooth for {it:xvarname}
        {cmd:r_}{it:xvarname}  partial residuals for {it:xvarname}

{pstd}
where {it:xvarname} denotes a member of {it:xvars}.

{pstd}
Each smooth has mean zero. A pointwise 95% confidence band for each smooth may
be calculated by adding +/- 1.96 times its standard error to each smooth.

 
{pstd}
{ul:{hi:Problem size}}

{pstd}
The largest problem (i.e. data+model) that can be fit is 36,000,000 single-precision
real numbers (floats). This quantity represents the
amount of storage space needed by the FORTRAN program, not the amount of data
stored in Stata. The problem size is approximated by the following formula:

        floats = 1000 * N * (#V^0.2)/25

{pstd}
where N is the number of observations in the problem and #V is the total number
of variables including the constant for a non-Cox model,
and {it:deadvar} if a Cox model is fit. For
example for a model with a constant and a single predictor (i.e. #V = 2) the
biggest problem that can be fit is N = 783495. Please note also that the FORTRAN
program has a hard-coded limit of #V <= 75.


{pstd}
{ul:{hi:Warning}}

{pstd}
We cannot vouch for the results from the FORTRAN software and have
occasionally noticed anomalies. However we believe it to be reliable in the
vast majority of instances. {cmd:gam.exe} can fail to converge with {cmd:cox} regression
and in earlier versions has been known to cause Stata to shut down without
warning. We find that this problem may be cured by changing either the
values of {cmd:df()} slightly, or even the order of the predictors in {it:xvars}.


{title:Examples}

{phang}{cmd:. use auto}{p_end}
{phang}{cmd:. gam mpg weight displ, df(weight:3, displ:4)}{p_end}
{phang}{cmd:. gam foreign mpg, family(binomial) df(3)}{p_end}
{phang}{cmd:. xi: gam foreign mpg i.rep78, family(binomial) df(mpg:2)}{p_end}

{phang}{cmd:. gen rate = dead/pyrs}{p_end}
{phang}{cmd:. gam rate age smoking [iweight = pyrs], df(3) family(poisson)}{p_end}

{phang}{cmd:. stset time, failure(dead)}{p_end}
{phang}{cmd:. gam age grad2 grad3 nodes, df(1, age nodes:4) family(stcox)}{p_end}


{title:Authors}

{phang}Patrick Royston{p_end}
{phang}MRC Clinical Trials Unit at UCL{p_end}
{phang}London, UK{p_end}
{phang}j.royston@ucl.ac.uk{p_end}

{phang}Gareth Ambler{p_end}
{phang}Dept of Statistical Science, UCL{p_end}
{phang}London, UK{p_end}
{phang}g.ambler@ucl.ac.uk{p_end}


{title:Reference}

{phang}
Hastie TJ, Tibshirani R. 1990. Generalized additive models. Chapman and Hall.


{title:Also see}

{psee}Article: {it:Stata Technical Bulletin} STB-42 sg79

{psee}
Online:  {helpb gamplot}, {helpb glm}{p_end}

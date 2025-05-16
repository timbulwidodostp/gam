{smcl}
{* 14may2014}{...}
{hline}
help for {hi:gamplot}{right:Patrick Royston, Gareth Ambler}
{hline}


{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:gamplot} {hline 2}}Generalized additive models plotter{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:gamplot}
{it:xvar}
[{it:xvar2}]
{ifin}
[{cmd:,}
{it:options}]


{synoptset 24}{...}
{marker mfpigen_options}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt abs(#)}}maximum permitted distance between smooth function and partial residual{p_end}
{synopt :{opt lev:el(#)}}sets the confidence level for 'error bands' to #{p_end}
{synopt :{opt noconf}}suppresses pointwise confidence intervals{p_end}
{synopt :{opt nopres}}suppresses partial residuals in the plot{p_end}
{synopt :{opt twoway_options}}options for {cmd:graph twoway}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:gamplot} plots the estimated function of {it:xvar} following use
of the {cmd:gam} command.  If {it:xvar2} is specified, the functions
are plotted against this variable, rather than against {it:xvar}.


{title:Options}

{phang}
{opt abs(#)} sets the maximum permitted distance between the smooth function
and partial residual.  Any partial residuals which exceed this value will 
not be plotted.  The user is made aware of this.  Default {it:#} is 1e15.

{phang}
{opt level(#)} determines the width of the pontwise confidence intervals.
The default is 95, which corresponds to 95% coverage (assuming the
estimated function is pointwise normal).

{phang}
{opt noconf} suppresses plotting of the pointwise confidence intervals.

{phang}
{opt nopres} suppresses the addition of partial residuals to the plot.

{phang}
{it:twoway_options} are options of {cmd:graph, twoway}.


{title:Examples}

{phang}{cmd:. gam y x, df(x:4) family(binomial)}

{phang}{cmd:. gamplot x, name(g1, replace)}

{phang}{cmd:. gam _t x1 x2, df(x1:2, x2:3) family(cox) dead(_d)}

{phang}{cmd:. gamplot x1 age, nopres level(99)}


{title:Authors}

{phang}Patrick Royston{p_end}
{phang}MRC Clinical Trials Unit at UCL{p_end}
{phang}London, UK{p_end}
{phang}j.royston@ucl.ac.uk{p_end}

{phang}Gareth Ambler{p_end}
{phang}Dept of Statistical Science, UCL{p_end}
{phang}London, UK{p_end}
{phang}g.ambler@ucl.ac.uk{p_end}


{title:Also see}

{psee}Article: {it:Stata Technical Bulletin} STB-42 sg79

{psee}
Online:  {helpb glm}, {helpb gam}{p_end}

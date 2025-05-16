*! v 2.0.11 PR/GA 29sep2011
program define gam, eclass
/*
	2.0.11/PR: gam.ado looksfor gam.exe in STB installation place by default, not c:\ado\personal
	fixed problem with temporary filenames not enclosed in compound quotes
	2.0.10/PR: fixed problem with temporary filenames not enclosed in compound quotes
			   now returns "gam" in e(cmd2) not e(cmd): problem with _rmdcoll after gam if use e(cmd).
	2.0.8/PR: translated to Stata 8/9
		    default gamfit.exe is HUGER (gamhug2.exe), now gam.exe - no disadvantage using it
	          fixed up incorrect estimates and deviance when all-linear (edf = 1) model fit
	          deviance for Gaussian model now scaled - calculated by offset method using residuals
	          output tidied up
	          reduce max name length from 28 to 19
	2.0.7/PR: increase max name length from 6 to 28
	2.0.6/PR: add HUGER option to fit bigger problems (uses gamhug2.exe)
	2.0.6/GA: fix save `tmp' problems (3 places) by surrounding with compound quotes
	2.0.5/GA: clear up bug in Stata 8 which merges too many observations (see line 539)
	2.0.4/PR: limited support for stcox
*/
version 8
if replay() {
	if "`e(cmd2)'"!="gam" error 301
	preserve
	_gamrslt
	exit
}
global S_E_gam

syntax varlist(min=1) [if] [in] [aw fw iw] [, ///
 Family(string) Link(string) DF(string) DEAD(varlist max=1) noMErge ///
 MIssing(real 9999) BTolerance(real .0005) LTolerance(real .001) noRefresh]

local maxlen 19

if missing("$GAMDIR") local dir `"`c(sysdir_plus)'g/"'
else local dir $GAMDIR
local gamprog `dir'gam.exe
local maxreal 36000
cap confirm file `gamprog'
local rc=_rc
errfile `rc' `gamprog'
/*
	Deal with family and link function
*/
local f = lower(trim("`family'"))
local lf = length("`f'")
if missing("`f'") local fam "gauss"
else if "`f'"==substr("binomial",1,`lf') local fam "binom"
else if "`f'"==substr("gamma",1,max(`lf',3)) local fam "gamma"
else if "`f'"==substr("gaussian",1,max(`lf',3)) local fam "gauss"
else if "`f'"==substr("poisson",1,`lf') local fam "poiss"
else if "`f'"==substr("cox",1,`lf')	local fam "cox"
else if "`f'"==substr("stcox",1,`lf') local fam "stcox"
else {
	di as err "unknown family() `f'"
	exit 198
}
local li = lower(trim("`link'"))
local lli = length("`li'")
if missing("`li'") {
	if "`fam'"=="gauss" local l "ident"
	else if "`fam'"=="binom" local l "logit"
	else if "`fam'"=="poiss" local l "logar"
	else if "`fam'"=="gamma" local l "inver"
	else if "`fam'"=="cox" | "`fam'"=="stcox" local l "cox"
}
else if "`li'"==substr("identity",1,max(`lli',3)) local l "ident"
else if "`li'"==substr("inverse",1,max(`lli',3)) local l "inver"
else if "`li'"==substr("cox",1,`lli') local l "cox"
else if "`li'"=="log" local l "logar"
else if "`li'"==substr("logit",1,`lli')	local l "logit"
else {
	di as err "invalid link `link'"
	exit 198
}
local interc "no"
if "`fam'"=="cox" {
	if missing("`dead'") {
		di as err "dead() required with cox"
		exit 198
	}
}
else if "`fam'"!="stcox" {
	if !missing("`dead'") {
		di as err "dead() invalid, not Cox model"
		exit 198
	}
	local interc "yes"
}
/*
	Deal with response and predictors
*/
if "`fam'"!="stcox" {
	gettoken y x:varlist
}
else {
	local y _t
	local x `varlist'
	local dead _d
	local fam cox
}
local nx 0
local longn
tokenize `x'
while !missing("`1'") {
	if length("`1'")>`maxlen' local longn "`longn' `1'"
	local nx = `nx'+1
	local x`nx' `1'
	mac shift
}
if !missing("`longn'") {
	di _n as txt "Length of variable(s)" as res /*
	*/ "`longn'" as txt " is/are >`maxlen' characters."
	di as txt "There may be problems if any name is not unique to `maxlen' chars."
}
/*
if !`nx' {
	di as err "insufficient predictors"
	exit 198
}
*/
/*
	Set up degrees of freedom for smoothers: Default is 1 df (linear)
*/
local d 1
forvalues i=1/`nx' {
	local df`i' `d'
}
local df_all1 1
if `nx'>0 & !missing("`df'") {
	tokenize "`df'", parse(",")
	local ncl 0 /* # of comma-delimited clusters */
	while !missing("`1'") {
		if "`1'"!="," {
			local ncl=`ncl'+1
			local clust`ncl' "`1'"
		}
		mac shift
	}
	if `ncl'>`nx' {
		di as err "too many df() values specified"
		exit 198
	}
/*
	Disentangle each varlist:string cluster
*/
	forvalues i=1/`ncl' {
		tokenize `clust`i'', parse("=:")	
		if "`2'"!=":" & "`2'"!="=" {
			local 3 `1'
			local 1 `x'
			local 2 ":"
		}
		local dfk `3'
		cap confirm num `dfk'
		if _rc {
			di as err "invalid df() value `dfk'"
			exit 198
		}
		if `dfk'<1 {
			di as err "invalid df() value `dfk'"
			exit 198
		}
		if `dfk'>1 local df_all1 0
		unab dfvars:`1'
		tokenize `dfvars'
		while !missing("`1'") {
			local dfv `1'
			local k 0
			local j 1
			while `j'<=`nx' {
				if "`dfv'"=="`x`j''" {
					local k `j'
					local j `nx'
				}
				local ++j
			}
			if !`k' {
				di as err "`dfv' must be one of the predictors"
				exit 198
			}
			local df`k' `dfk'
			mac shift
		}
	}
}
if `df_all1' {
	di as txt _n "[model is linear, not a GAM---all the df are 1]"
	// Can't rely on gamfit to get this model right, so estimate it via regress/logit/glm/cox.
	// Change link names for compatibility with -glm-.
	if "`l'"=="logar" local l log
	else if "`l'"=="inver" local l power -1
	if "`fam'"=="poiss" | "`fam'"=="gamma" {
		glm `y' `x' `if' `in' [`weight'`exp'], family(`fam') link(`l')
		ereturn scalar dev = e(deviance)	// for compatibility with gamfit
		exit
	}
	if "`fam'"=="gauss" {
		if "`l'"=="ident" {
			regress `y' `x' `if' `in' [`weight'`exp']
		}
		else {
			glm `y' `x' `if' `in' [`weight'`exp'], family(gaussian) link(`l')
		}
	}
	else if "`fam'"=="binom" {
		if "`l'"=="logit" {
			logit `y' `x' `if' `in' [`weight'`exp']
		}
		else {
			glm `y' `x' `if' `in' [`weight'`exp'], family(binomial) link(`l')
		}
	}
	else if "`fam'"=="cox" {
		cox `y' `x' `if' `in' [`weight'`exp'], dead(`dead')
	}
	ereturn scalar dev = -2*e(ll)
	exit
}
marksample touse
markout `touse' `dead'
/*
	Weights
*/
qui if !missing("`exp'") {
	tempvar wt
	gen `wt' `exp'
	replace `wt'=. if `wt'<=0
	markout `touse' `wt'
	if "`weight'"=="aweight" {
		sum `wt' if `touse'
		replace `wt' = `wt'/r(mean)
	}
}
/*
	Estimate storage for gam*.exe
*/
local vsize=`nx'+1+!missing("`exp'")	/* 1 is for either constant or dead */
qui count if `touse'
local lworkr=int(.5+r(N)*(`vsize'^.2)/25)
if `lworkr'>`maxreal' {
	di as txt "[Approximate problem size: " `lworkr' "000 reals. " /*
	 */ "Available:" `maxreal' "000 reals.]"
	di as err "problem is too big for `gamprog'"
	exit 2002
}
/*
	Save "index" variable to keep track
	of data order for later merge
*/
quietly {
	* clean up _merge
	cap drop _merge
	sort `x'
	cap drop _index
	gen long _index=_n
/*
	Output data and $.mod files for gamfit.exe
*/
	preserve
	if !missing("`refresh'") {
		cap confirm file $.dat
		if _rc {
			noi di as err "GAM data file $.dat not found"
			exit 601
		}
		cap confirm file $.inx
		if _rc {
			noi di as err "GAM index file $.inx not found"
			exit 601
		}
		* read predictor SDs before ereturn clear
		forvalues i=1/`nx' {
			tempname s`i'
			scalar `s`i''=e(gam_s`i')
		}
 	}
	else {
		drop if `touse'==0
		tempvar s
		gen byte `s'=0
		forvalues i=1/`nx' {
			local xi `x`i''
/*
	Count df for xi (#distinct values)
*/
			sort `xi'
			by `xi': replace `s'=(_n==1 & `xi'!=`missing')
			summ `s', meanonly
			local GAMd`i' `r(sum)'
			if `GAMd`i''<=`df`i'' {
				noi di as err "`df`i'' df for `xi' are too many" /*
				 */ "---only " `GAMd`i'' " distinct values"
				exit 2001
			}
/*
	Standardize each x (including binary predictors)
*/
			sum `xi' if `xi'!=`missing'
			replace `xi'=(`xi'-r(mean))/r(sd) if `xi'!=`missing'
			tempname s`i'
			scalar `s`i''=r(sd) /* sd of predictor */
		}
		sort _index
		format `y' `x' `wt' `dead' %9.0g	/* to avoid truncation */
		outfile `y' `x' `wt' `dead' using $.dat, comma replace nolabel
		keep _index
		save $.inx, replace
	}
/*
	Create model specification file.
*/
	local i 1
	local model`i'=ltrim("'DATA: ', '$'")
	local ++i
	local model`i'=ltrim("'P: '," /*
	 */ +string(1+`nx'+("`fam'"=="cox")+!missing("`exp'")))
	local ++i
	local model`i'=ltrim("'N: ', -1")
	local ++i
	local model`i'=ltrim("'FORMAT: ', 'free'")
	local ++i
	local model`i'=ltrim("'MISSING-CODE: ',"+string(`missing'))
	local ++i
	local model`i'=ltrim("'INTERCEPT: ', `interc'")
	local ++i
	local model`i'=ltrim("'VARIABLE NAME         MODE           DF'")
	local ++i
	local model`i'=ltrim("'`y'', 'response', 0")
	local ++i
	forvalues j=1/`nx' {
		local model`i'=ltrim("'`x`j''','predictor',"+string(`df`j''))
		local ++i
	}
	if !missing("`exp'") {
		local model`i'=ltrim("'`wt'', 'weight', 0")
		local ++i
	}
	if "`fam'"=="cox" {
		local model`i'=ltrim("'`dead'', 'censoring', 0")
		local ++i
	}
	local model`i'=ltrim("'FAMILY: ', '`fam''")
	local ++i
	local model`i'=ltrim("'LINK: ', '`l''")
	local ++i
/*
	H & T use .001, .001 as tolerances for convergence of local scoring
	and backfitting respectively, while suggesting .0005 for latter in program.
	We use ltolera=.001 (default) and .0005 for greater safety.
	
	17May2002: now adding user option btolerance with default .0005.
*/
	local model`i'=ltrim("'THRESHOLDS: ',"+string(`ltolerance')+", "+string(`btolerance'))
	local ++i
/*
	H & T use 20, 15 as max iterations for local scoring and backfitting.
	We use 40, 30 for greater safety.
*/
	local model`i'=ltrim("'MAX ITERS: ', 40, 30")
	local nspec `i'
	drop _all
	set obs `nspec'
	tempvar model
	gen str44 `model'=""
	local blank48 "                                                "
	forvalues i=1/`nspec' {
		replace `model'=substr("`model`i''`blank48'",1,44) in `i'
	}
	outfile `model' using $.mod, replace noquote
	!`gamprog'
/*
	Read model summary statistics
*/
	drop _all
	cap infile stats using $.out
	local rc=_rc
	errfile `rc' $.out
	tempname fault nobs tdf devpen scale ll
	scalar `fault'=int(stats[1]+.5)	/* fault code */
	scalar `nobs'=int(stats[2]+.5)	/* number of observations */
	scalar `tdf'=stats[3]		/* error degrees of freedom */
	scalar `devpen'=stats[4]		/* penalized deviance */
	scalar `scale'=stats[5]		/* estimated scale parameter */
/*
	Read fit, residuals and predictors
*/
	drop _all
	if missing("`merge'") {
/*
	Dropping GAM_res and GAM_sres because seem fairly useless.
	Anyway, don't know what GAM_res is for Cox models.
*/
		if ("`fam'"!="cox") {
			cap infile `y' GAM_mu GAM_res GAM_sres `x' using $.fit
			local rc=_rc
			errfile `rc' $.fit
			keep GAM_mu
			label var GAM_mu "GAM fitted values"
			tempfile tmp
			save `"`tmp'"'
		}
/*
	Read individual smooths, confidence bands and partial residuals
*/
		forvalues i=1/`nx' {
			local vname=substr("`x`i''",1,`maxlen')
			drop _all
			cap infile `x`i'' s_`vname' l_`vname' h_`vname'/*
			 */  r_`vname' using `x`i''.gra
			local rc=_rc
			errfile `rc' `x`i''.gra
/*
	SE from confidence band
*/
			gen e_`vname'=(h_`vname'-s_`vname')/1.96
			lab var s_`vname' "GAM `df`i'' df smooth for `x`i''"
			lab var e_`vname' "GAM SE of smooth for `x`i''"
/*
	Cox: Standardize each smooth to mean zero
*/
			if "`fam'"=="cox" {
				sort `x`i''
				drop r_`vname'
				sum s_`vname'
				replace s_`vname'=s_`vname'-r(mean)
			}
			else lab var r_`vname' "GAM partial residual for `x`i''"
			drop `x`i'' h_`vname' l_`vname'
			tempfile tmp`i'
			save `"`tmp`i''"'
		}
		if "`fam'"!="cox" {
			use `"`tmp'"', clear
			forvalues i=1/`nx' {
				merge using `"`tmp`i''"'
				drop _merge
			}
/*
	Merge with index values
*/
			compress
			merge using $.inx
			drop _merge
			sort _index
			save `"`tmp'"', replace
		}
	}
/*
	Drop variables that might be left over from previous run of gamfit.exe
	Read in summary statistics
*/
	cap drop _all
	cap infile dof slope se z gain pvalue using $.sum
	local rc=_rc
	errfile `rc' $.sum
	local nv1=`nx'+("`fam'"!="cox")
	if `nv1'!=_N {
		di as err "inconsistency found when reading GAM results from file $.sum"
		exit 2002
	}
/*
	Store quantities needed to be saved as e() later
*/
	tempname b se
	forvalues i=1/`nv1' {
		if "`fam'"!="cox" & `i'==`nv1' { 
			local j 0
			local x`nv1' _cons
		}
		else local j `i'
		scalar `b'=slope[`i']
		scalar `se'=se[`i']
		local gam_x`j' `x`i''
		local gam_df`j'=dof[`i'] 
		local gam_z`j'=z[`i'] 
		local gam_gn`j'=gain[`i']
		local gam_p`j'=pvalue[`i'] 
		if `j' {
			scalar `b'=`b'/`s`i''
			scalar `se'=`se'/`s`i''
			local gam_s`i'=`s`i''
		}
		local gam_sl`j'=`b' /* slope */ 
		local gam_se`j'=`se' /* se(slope) */
	}
	restore
	cap drop GAM_mu
	forvalues i=1/`nx' {
		local vname=substr("`x`i''",1,`maxlen')
		cap drop s_`vname'
		cap drop e_`vname'
		cap drop r_`vname'
	}
/*
	Tidy up files left by gam.ado and gam*.exe
*/
	forvalues i=1/`nx' {
		erase `x`i''.gra
	}
	erase $.mod
	erase $.fit
	erase $.out
	erase $.sum
}
qui if missing("`merge'") {
/*
	Merge existing data with data from gamfit run
*/
	if "`fam'"!="cox" {
		sort _index
		merge _index using `"`tmp'"'
		drop _merge
	}
	else {
		gen GAM_mu=0
		tempvar nouse ximpute
		gen byte `nouse'=1-`touse'
		gen `ximpute'=0
		forvalues i=1/`nx' {
			count if `x`i''==`missing'
			if r(N) {
				replace `ximpute'=`x`i''
				summ `x`i'' if `x`i''!=`missing'	
				replace `ximpute'=r(mean) if `x`i''==`missing'
				sort `nouse' `ximpute'
			}
			else sort `nouse' `x`i''
			merge using `"`tmp`i''"'
			drop _merge
			local vname=substr("`x`i''",1,`maxlen')
			replace GAM_mu=GAM_mu+s_`vname'
		}			
	}
	drop if missing(_index) 
	count
	noi di _n as res r(N) as txt " records merged."
/*
	Compute and store scaled deviance for Gaussian models
	(gamfit returns unscaled deviance = rss). Uses, effectively, offset of GAM_mu.
*/
	if "`fam'"=="gauss" {
		tempvar res
		gen `res' = `y'-GAM_mu
		regress `res' if `touse' [`weight'`exp']
		local deviance = -2*e(ll)
	}
	else local deviance = `devpen'
	cap drop _index
}
ereturn clear
ereturn scalar dev = `deviance'
ereturn scalar devpen = `devpen'
ereturn scalar disp = `scale'
ereturn scalar nobs = `nobs'
ereturn scalar tdf = `tdf'
ereturn scalar missing = `missing' /* missing value code */
ereturn local dead `dead'
ereturn local depv `y'
ereturn local fam `fam'
ereturn local link `l'
ereturn local vl `x'
forvalues i=1/`nv1' {
	if "`fam'"!="cox" & `i'==`nv1' local j 0
	else local j `i'
	ereturn local gam_x`j' `gam_x`j''
	ereturn scalar gam_df`j' = `gam_df`j''
	ereturn scalar gam_z`j' = `gam_z`j'' 
	ereturn scalar gam_gn`j' = `gam_gn`j''
	ereturn scalar gam_p`j' = `gam_p`j'' 
	if `j' ereturn scalar gam_s`i' = `gam_s`i''
	ereturn scalar gam_sl`j' = `gam_sl`j'' /* slope */ 
	ereturn scalar gam_se`j' = `gam_se`j'' /* se(slope) */
}
_gamrslt
ereturn local cmd2 gam
end

program define _gamrslt
* GAM results
local maxlen 19
local flo "family `e(fam)', link `e(link)'."
di _n as txt "Generalized Additive Model with `flo'"
#delimit ;
di _n as txt "Model df     = " as res %9.3f e(nobs)-e(tdf)
	_col(52) as txt "No. of obs = "  as res %9.0g e(nobs) ;
di as txt "Deviance     = "  as res %9.0g e(devpen)
	_col(52) as txt "Dispersion = "  as res %9.0g e(disp) ;
#delimit cr
local skip=12-length("`e(depv)'")
di as txt "{hline 13}{c TT}{hline 59}"
di as txt _skip(`skip') /*
 */ "`e(depv)' {c |}   df    Lin. Coef.  Std. Err.      z        Gain    P>Gain"
di as txt "{hline 13}{c +}{hline 59}"
tempname tg totdf b se
scalar `tg'=0
scalar `totdf'=0
local nx: word count `e(vl)'
local nv1=`nx'+("`e(fam)'"!="cox")
local i 0
while `i'<`nv1' {
	local ++i
	if "`e(fam)'"!="cox" & `i'==`nv1' local i 0
	local v = abbrev("`e(gam_x`i')'", 12)
	local skip=12-length("`v'")
	if abs(e(gam_df`i')-1)<1e-6 {
		local fmt %4.0f _skip(3)
	}
	else {
		local fmt %7.3f
		scalar `tg'=`tg'+e(gam_gn`i')
		scalar `totdf'=`totdf'+e(gam_df`i')-1
	}
	di as txt _skip(`skip') "`v' {c |}" /*
	 */ as res `fmt' e(gam_df`i') "  " /*
	 */ as res %9.0g e(gam_sl`i') "  " /*
	 */ as res %9.0g e(gam_se`i') " " /*
	 */ as res %9.3f e(gam_z`i') " " /*
	 */ as res %9.3f e(gam_gn`i') " " /*
	 */ as res %9.4f e(gam_p`i')
	 if `i'==0 local i `nv1'
}
di as txt "{hline 13}{c BT}{hline 59}"
di as txt "Total gain (nonlinearity chisquare) = " as res %9.3f `tg' /*
 */ as txt " (" as res %5.3f `totdf' as txt " df), P = " /*
 */ as res %6.4f chiprob(`totdf',`tg')
end

program define errfile
* 1=rc, 2=file giving problems.
if `1' {
	noi di as err "GAMFIT failure, `2' not found"
	exit `rc'
}
end

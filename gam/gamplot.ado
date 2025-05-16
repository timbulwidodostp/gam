*! version 3.0.1 PR 13apr2011
program define gamplot, sortpreserve
	version 8
	if "`e(cmd2)'"!="gam" {
		error 301
	}

	syntax varlist(min=1 max=2) [if] [in] [, LEVel(cilevel) noci noPRES abs(real 1e15) *]

	_get_gropts , graphopts(`options') 	///
		getallowed(PLOTOPts CIOPts LINEOPts RLOPts plot addplot)
	local options `"`s(graphopts)'"'
	local ciopts `"`s(ciopts)'"'
	local rlopts `"`s(rlopts)'"'
	local lopts `"`s(lineopts)'"'
	local plopts `"`s(plotopts)'"'
	local plot `"`s(plot)'"'
	local addplot `"`s(addplot)'"'
	_check4gropts ciopts, opt(`ciopts')
	_check4gropts rlopts, opt(`rlopts')
	_check4gropts lineopts, opt(`lopts')
	_check4gropts plotopts, opt(`plopts')


******************************************************
	if "`e(fam)'"=="cox" local pres nopres
	local maxlen 19
	tokenize `varlist'
	local x = substr("`1'", 1, `maxlen')
	local xvar = cond(missing("`2'"), "`1'", "`2'")
	quietly {
		if "`ci'"!="noci" {
			tempname z
			scalar `z' = invnorm((100+`level')/200)
			tempvar top bot
			gen `top' = s_`x'+`z'*e_`x'
			gen `bot' = s_`x'-`z'*e_`x'
		}
		tempvar partres
		if "`pres'"!="nopres" {
			gen `partres' = r_`x'
			lab var `partres' "GAM partial residuals for `x'"
/*
	Option for excluding points which destroy the scaling
*/
			count if abs(s_`x'-r_`x')>`abs'
			local excl = r(N)
			if `excl' {
				if `excl'>1 local s s
				noi di as txt "[`excl' point`s' excluded from plot]"
				replace `partres'=. if abs(s_`x'-r_`x')>`abs'
			}
		}
		else gen `partres' = .
		count if `xvar'==e(missing)
		if r(N)>0 {
			local nimpute `r(N)'
			if `nimpute'>1 local s s
			else local s
			noi di as txt "[`nimpute' imputed point`s' included in plot]"
			local xlabel: var lab `xvar'
			tempvar ximpute
			gen `ximpute' = `xvar'
			qui sum `xvar' if `xvar'!=e(missing)
			replace `ximpute' = r(mean) if `xvar'==e(missing)
			lab var `ximpute' "`xlabel'"
			local xvar `ximpute'
		}
	}
	if `"`plot'`addplot'"' == "" {
		local legend legend(nodraw)
	}
	/*
		Component (-plus partial-residual) plot
	*/
	local yttl "Component & partial residuals for `e(depv)'"
	local xttl : var label `xvar'
	if `"`xttl'"' == "" local xttl `xvar'
	local title : var label s_`x'
	local nx : word count `e(vl)'
	if `nx'>1 {
		local title `"`"`title',"' "adjusted for covariates""'
	}
	sort `xvar', stable
	graph twoway	///
	(rarea `bot' `top' `xvar'			/// the CI bands
		`if' `in',			///
		pstyle(ci)			///
		`ciopts'			///
	)					///
	(scatter `partres' `xvar'			/// partial residuals
		`if' `in',			///
		title(`title')			/// no `""' on purpose
		ytitle(`"`yttl'"')		///
		xtitle(`"`xttl'"')		///
		pstyle(p1)			///
		`legend'			///
		`options'			///
		`plopts'			///
	)					///
	(line s_`x' `xvar'			/// the fit
		`if' `in',			///
		lstyle(refline)			///
		pstyle(p2)			///
		`rlopts'			///
		`lopts'				///
	)					///
	|| `plot' || `addplot'			///
	// blank
end

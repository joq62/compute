%% This is the application resource file (.app file) for the 'base'
%% application.
{application, common,
[{description, "Mnesia based distributed dbase" },
{vsn, "0.1.0" },
{modules, 
	  [common,common_sup,common_server]},
{registered,[common]},
{applications, [kernel,stdlib]},
{mod, {common,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/common.git"},
{env,[]}
]}.

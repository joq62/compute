%% This is the application resource file (.app file) for the 'base'
%% application.
{application, compute,
[{description, "Boot service for raspberry boards" },
{vsn, "0.1.0" },
{modules, 
	  [compute,compute_sup,compute_server]},
{registered,[compute]},
{applications, [kernel,stdlib]},
{mod, {compute_app,[]}},
{start_phases, []},
{env,[]}
]}.

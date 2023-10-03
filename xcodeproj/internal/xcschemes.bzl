"""Module for defining custom Xcode schemes (`.xcscheme`s)."""

load(":memory_efficiency.bzl", "EMPTY_STRING")

### Public

# Scheme

def _scheme(name, *, profile = "same_as_run", run = None, test = None):
    """Defines a custom scheme.

    Args:
        name: The name of the scheme.
        profile: A value returned by `xcschemes.profile`, or the string
            `"same_as_run"`. If `"same_as_run"`, the same targets will be built
            for the Profile action as are built for the Run action (defined by
            `xcschemes.run`). If `None`, `xcschemes.profile()` will be used,
            which means no targets will be built for the Profile action.
        run: A value returned by `xcschemes.run`. If `None`, `xcschemes.run()`
            will be used.
        test: A value returned by `xcschemes.test`. If `None`,
            `xcschemes.test()` will be used.
    """
    if not name:
        fail("Name must be provided to `xcschemes.scheme`.")

    return struct(
        name = name,
        profile = profile,
        run = run,
        test = test,
    )

# Actions

def _profile(
        *,
        args = [],
        build_targets = [],
        env = {},
        env_include_default = True,
        launch_target = None,
        use_run_args_and_env = None,
        xcode_configuration = None):
    if use_run_args_and_env == None:
        use_run_args_and_env = not (args or env)

    return struct(
        args = args,
        build_targets = build_targets,
        env = env,
        env_include_default = env_include_default,
        launch_target = launch_target,
        use_run_args_and_env = use_run_args_and_env,
        xcode_configuration = xcode_configuration or EMPTY_STRING,
    )

def _run(
        *,
        args = [],
        build_targets = [],
        diagnostics = None,
        env = {},
        env_include_default = True,
        launch_target = None,
        xcode_configuration = None):
    return struct(
        args = args,
        build_targets = build_targets,
        diagnostics = diagnostics,
        env = env,
        env_include_default = env_include_default,
        launch_target = launch_target,
        xcode_configuration = xcode_configuration or EMPTY_STRING,
    )

def _test(
        *,
        args = [],
        build_targets = [],
        diagnostics = None,
        env = {},
        env_include_default = True,
        test_targets = [],
        use_run_args_and_env = None,
        xcode_configuration = None):
    if use_run_args_and_env == None:
        use_run_args_and_env = not (args or env)

    return struct(
        args = args,
        build_targets = build_targets,
        diagnostics = diagnostics,
        env = env,
        env_include_default = env_include_default,
        test_targets = test_targets,
        use_run_args_and_env = use_run_args_and_env,
        xcode_configuration = xcode_configuration or EMPTY_STRING,
    )

# Targets

def _launch_target(
        label,
        *,
        extension_host = None,
        library_targets = [],
        post_actions = [],
        pre_actions = [],
        target_environment = None,
        working_directory = None):
    if not label:
        fail("Label must be provided to `xcschemes.launch_target`.")

    return struct(
        extension_host = extension_host or EMPTY_STRING,
        label = label,
        library_targets = library_targets,
        post_actions = post_actions,
        pre_actions = pre_actions,
        target_environment = target_environment,
        working_directory = working_directory or EMPTY_STRING,
    )

def _library_target(label, *, post_actions = [], pre_actions = []):
    if not label:
        fail("Label must be provided to `xcschemes.library_target`.")

    return struct(
        label = label,
        post_actions = post_actions,
        pre_actions = pre_actions,
    )

def _test_target(
        label,
        *,
        enabled = True,
        library_targets = [],
        post_actions = [],
        pre_actions = [],
        target_environment = None):
    if not label:
        fail("Label must be provided to `xcschemes.test_target`.")

    return struct(
        enabled = enabled,
        label = label,
        library_targets = library_targets,
        post_actions = post_actions,
        pre_actions = pre_actions,
        target_environment = target_environment,
    )

def _top_level_build_target(
        label,
        *,
        extension_host = None,
        library_targets = [],
        post_actions = [],
        pre_actions = [],
        target_environment = None):
    if not label:
        fail("Label must be provided to `xcschemes.top_level_build_target`.")

    return struct(
        extension_host = extension_host or EMPTY_STRING,
        include = True,
        label = label,
        library_targets = library_targets,
        post_actions = post_actions,
        pre_actions = pre_actions,
        target_environment = target_environment,
    )

def _top_level_anchor_build_target(
        label,
        *,
        extension_host = None,
        library_targets,
        target_environment = None):
    if not label:
        fail("""\
Label must be provided to `xcscheme.top_level_anchor_build_target`.
"""
        )
    if not library_targets:
        fail("""\
`library_targets` must be non-empty for `xcscheme.top_level_anchor_build_target`
"""
        )

    return struct(
        extension_host = extension_host or EMPTY_STRING,
        include = False,
        label = label,
        library_targets = library_targets,
        post_actions = [],
        pre_actions = [],
        target_environment = target_environment,
    )

# `pre_post_actions`

def _build_script(title, *, order = None, script_text):
    return struct(
        for_build = True,
        order = order,
        script_text = script_text,
        title = title,
    )

def _launch_script(title, *, order = None, script_text):
    return struct(
        for_build = False,
        order = order,
        script_text = script_text,
        title = title,
    )

_pre_post_actions = struct(
    build_script = _build_script,
    launch_script = _launch_script,
)

# Other

def _arg_or_env(value, *, enabled = True):
    return struct(
        enabled = enabled,
        value = value,
    )

def _diagnostics(
        *,
        address_sanitizer = False,
        thread_sanitizer = False,
        undefined_behavior_sanitizer = False):
    if address_sanitizer and thread_sanitizer:
        fail("Address Sanitizer cannot be used together with Thread Sanitizer.")

    return struct(
        address_sanitizer = address_sanitizer,
        thread_sanitizer = thread_sanitizer,
        undefined_behavior_sanitizer = undefined_behavior_sanitizer
    )

# API

xcschemes = struct(
    arg = _arg_or_env,
    diagnostics = _diagnostics,
    env = _arg_or_env,
    launch_target = _launch_target,
    library_target = _library_target,
    pre_post_actions = _pre_post_actions,
    profile = _profile,
    run = _run,
    scheme = _scheme,
    test = _test,
    test_target = _test_target,
    top_level_anchor_build_target = _top_level_anchor_build_target,
    top_level_build_target = _top_level_build_target,
)

### Internal

# Resolve labels (macro)

def _resolve_build_target_labels(build_target):
    return struct(
        extension_host = _resolve_label(build_target.extension_host),
        include = build_target.include,
        label = _resolve_label(build_target.label),
        library_targets = [
            _resolve_library_target_labels(library_target)
            for library_target in build_target.library_targets
        ],
        post_actions = build_target.post_actions,
        pre_actions = build_target.pre_actions,
        target_environment = build_target.target_environment,
    )

def _resolve_label(label_str):
    if not label_str:
        return EMPTY_STRING
    return str(native.package_relative_label(label_str))

def _resolve_labels(schemes):
    return [
        _resolve_scheme_labels(scheme)
        for scheme in schemes
    ]

def _resolve_launch_target_labels(launch_target):
    if not launch_target or type(launch_target) == "string":
        return _resolve_label(launch_target)

    return struct(
        extension_host = _resolve_label(launch_target.extension_host),
        label = _resolve_label(launch_target.label),
        library_targets = [
            _resolve_library_target_labels(library_target)
            for library_target in launch_target.library_targets
        ],
        post_actions = launch_target.post_actions,
        pre_actions = launch_target.pre_actions,
        target_environment = launch_target.target_environment,
        working_directory = launch_target.working_directory,
    )

def _resolve_library_target_labels(library_target):
    if type(library_target) == "string":
        return _resolve_label(library_target)

    return struct(
        label = _resolve_label(library_target.label),
        post_actions = library_target.post_actions,
        pre_actions = library_target.pre_actions,
    )

def _resolve_scheme_labels(scheme):
    return struct(
        name = scheme.name,
        profile = _resolve_profile_labels(scheme.profile),
        run = _resolve_run_labels(scheme.run),
        test = _resolve_test_labels(scheme.test),
    )

def _resolve_profile_labels(profile):
    if not profile or profile == "same_as_run":
        return profile

    return struct(
        args = profile.args,
        build_targets = [
            _resolve_build_target_labels(build_target)
            for build_target in profile.build_targets
        ],
        env = profile.env,
        env_include_default = profile.env_include_default,
        launch_target = _resolve_launch_target_labels(profile.launch_target),
        use_run_args_and_env = profile.use_run_args_and_env,
        xcode_configuration = profile.xcode_configuration,
    )

def _resolve_run_labels(run):
    if not run:
        return None

    return struct(
        args = run.args,
        build_targets = [
            _resolve_build_target_labels(build_target)
            for build_target in run.build_targets
        ],
        diagnostics = run.diagnostics,
        env = run.env,
        env_include_default = run.env_include_default,
        launch_target = _resolve_launch_target_labels(run.launch_target),
        xcode_configuration = run.xcode_configuration,
    )

def _resolve_test_labels(test):
    if not test:
        return None

    return struct(
        args = test.args,
        build_targets = [
            _resolve_build_target_labels(build_target)
            for build_target in test.build_targets
        ],
        diagnostics = test.diagnostics,
        env = test.env,
        env_include_default = test.env_include_default,
        test_targets = [
            _resolve_test_target_labels(test_target)
            for test_target in test.test_targets
        ],
        use_run_args_and_env = test.use_run_args_and_env,
        xcode_configuration = test.xcode_configuration,
    )

def _resolve_test_target_labels(test_target):
    if type(test_target) == "string":
        return _resolve_label(test_target)

    return struct(
        enabled = test_target.enabled,
        label = _resolve_label(test_target.label),
        library_targets = [
            _resolve_library_target_labels(library_target)
            for library_target in test_target.library_targets
        ],
        post_actions = test_target.post_actions,
        pre_actions = test_target.pre_actions,
        target_environment = test_target.target_environment,
    )

# Infos (rule)

def _create_arg_env_info(arg_env):
    if type(arg_env) == "string":
        return struct(
            enabled = True,
            value = arg_env,
        )

    return struct(
        enabled = arg_env["enabled"],
        value = arg_env["value"],
    )

def _create_build_target_infos(
        build_target,
        *,
        top_level_deps,
        xcode_configuration):
    if type(build_target) == "string":
        return [
            struct(
                id = _get_top_level_id(
                    target_environment = None,
                    top_level_deps = top_level_deps,
                    top_level_label = build_target,
                    xcode_configuration = xcode_configuration,
                ),
                post_actions = [],
                pre_actions = [],
            ),
        ]

    target_ids = _get_target_ids(
        target_environment = build_target["target_environment"],
        top_level_deps = top_level_deps,
        top_level_label = build_target["label"],
        xcode_configuration = xcode_configuration,
    )

    if build_target["include"]:
        build_targets = [
            struct(
                id = target_ids.id,
                post_actions = _create_pre_post_action_infos(
                    build_target["post_actions"]
                ),
                pre_actions = _create_pre_post_action_infos(
                    build_target["pre_actions"]
                ),
            ),
        ]
    else:
        build_targets = []

    build_targets.extend([
        _create_library_target_info(
            library_target,
            target_ids = target_ids.deps,
        )
        for library_target in build_target["library_targets"]
    ])

    return build_targets

def _create_diagnostics_info(diagnostics):
    if not diagnostics:
        return struct(
            address_sanitizer = False,
            thread_sanitizer = False,
            undefined_behavior_sanitizer = False,
        )

    return struct(
        address_sanitizer = diagnostics["address_sanitizer"],
        thread_sanitizer = diagnostics["thread_sanitizer"],
        undefined_behavior_sanitizer = (
            diagnostics["undefined_behavior_sanitizer"]
        ),
    )

def _create_infos(json_str, *, default_xcode_configuration, top_level_deps):
    return [
        _create_scheme_info(
            scheme,
            default_xcode_configuration = default_xcode_configuration,
            top_level_deps = top_level_deps,
        )
        for scheme in json.decode(json_str)
    ]

def _create_launch_target_info(
        launch_target,
        *,
        top_level_deps,
        xcode_configuration):
    if not launch_target:
        return (
            struct(
                extension_host = EMPTY_STRING,
                id = EMPTY_STRING,
                library_targets = [],
                post_actions = [],
                pre_actions = [],
                working_directory = EMPTY_STRING,
            ),
            [],
        )

    if type(launch_target) == "string":
        return (
            struct(
                extension_host = EMPTY_STRING,
                id = _get_top_level_id(
                    target_environment = None,
                    top_level_deps = top_level_deps,
                    top_level_label = launch_target,
                    xcode_configuration = xcode_configuration,
                ),
                library_targets = [],
                post_actions = [],
                pre_actions = [],
                working_directory = EMPTY_STRING,
            ),
            [],
        )

    target_ids = _get_target_ids(
        target_environment = launch_target["target_environment"],
        top_level_deps = top_level_deps,
        top_level_label = launch_target["label"],
        xcode_configuration = xcode_configuration,
    )

    extension_host_label = launch_target["extension_host"]
    if extension_host_label:
        extension_host = _get_top_level_id(
            target_environment = launch_target["target_environment"],
            top_level_deps = top_level_deps,
            top_level_label = extension_host_label,
            xcode_configuration = xcode_configuration,
        )
    else:
        extension_host = EMPTY_STRING

    launch_target_info = struct(
        extension_host = extension_host,
        id = target_ids.id,
        post_actions = _create_pre_post_action_infos(
            launch_target["post_actions"]
        ),
        pre_actions = _create_pre_post_action_infos(
            launch_target["pre_actions"]
        ),
        working_directory = launch_target["working_directory"],
    )

    library_targets = [
        _create_library_target_info(
            library_target,
            target_ids = target_ids.deps,
        )
        for library_target in launch_target["library_targets"]
    ]

    return (launch_target_info, library_targets)

def _create_library_target_info(
        library_target,
        *,
        target_ids):
    if type(library_target) == "string":
        return struct(
            label = _get_library_target_id(
                library_target,
                target_ids = target_ids,
            ),
            post_actions = [],
            pre_actions = [],
        )

    return struct(
        label = _get_library_target_id(
            library_target["label"],
            target_ids = target_ids,
        ),
        post_actions = _create_pre_post_action_infos(
            library_target["post_actions"],
        ),
        pre_actions = _create_pre_post_action_infos(
            library_target["pre_actions"],
        ),
    )

def _create_pre_post_action_info(pre_post_action):
    return struct(
        for_build = pre_post_action["for_build"],
        order = pre_post_action["order"],
        script_text = pre_post_action["script_text"],
        title = pre_post_action["title"],
    )

def _create_pre_post_action_infos(pre_post_actions):
    return [
        _create_pre_post_action_info(pre_post_action)
        for pre_post_action in pre_post_actions
    ]

def _create_profile_info(
        profile,
        *,
        default_xcode_configuration,
        run,
        top_level_deps):
    if profile == "same_as_run":
        return struct(
            args = [],
            build_targets = run.build_targets,
            env = {},
            env_include_default = False,
            launch_target = run.launch_target,
            use_run_args_and_env = True,
            xcode_configuration = EMPTY_STRING,
        )

    if not profile:
        (launch_target, _) = _create_launch_target_info(
            None,
            top_level_deps = top_level_deps,
            xcode_configuration = default_xcode_configuration,
        )

        return struct(
            args = [],
            build_targets = [],
            env = {},
            env_include_default = False,
            launch_target = launch_target,
            use_run_args_and_env = True,
            xcode_configuration = EMPTY_STRING,
        )

    xcode_configuration = profile["xcode_configuration"]

    resolving_xcode_configuration = (
        xcode_configuration or
        default_xcode_configuration
    )

    (launch_target, build_targets) = _create_launch_target_info(
        profile["launch_target"],
        top_level_deps = top_level_deps,
        xcode_configuration = resolving_xcode_configuration,
    )

    build_targets.extend([
        info
        for build_target in profile["build_targets"]
        for info in _create_build_target_infos(
            build_target,
            top_level_deps = top_level_deps,
            xcode_configuration = resolving_xcode_configuration,
        )
    ])

    return struct(
        args = [_create_arg_env_info(arg) for arg in profile["args"]],
        build_targets = build_targets,
        env = {
            key: _create_arg_env_info(value)
            for key, value in profile["env"].items()
        },
        env_include_default = profile["env_include_default"],
        launch_target = launch_target,
        use_run_args_and_env = profile["use_run_args_and_env"],
        xcode_configuration = xcode_configuration,
    )

def _create_run_info(run, *, default_xcode_configuration, top_level_deps):
    if not run:
        (launch_target, _) = _create_launch_target_info(
            None,
            top_level_deps = top_level_deps,
            xcode_configuration = default_xcode_configuration,
        )

        return struct(
            args = [],
            build_targets = [],
            diagnostics = _create_diagnostics_info(None),
            env = {},
            env_include_default = True,
            launch_target = launch_target,
            xcode_configuration = EMPTY_STRING,
        )

    xcode_configuration = run["xcode_configuration"]
    resolving_xcode_configuration = (
        xcode_configuration or
        default_xcode_configuration
    )

    (launch_target, build_targets) = _create_launch_target_info(
        run["launch_target"],
        top_level_deps = top_level_deps,
        xcode_configuration = resolving_xcode_configuration,
    )

    build_targets.extend([
        info
        for build_target in run["build_targets"]
        for info in _create_build_target_infos(
            build_target,
            top_level_deps = top_level_deps,
            xcode_configuration = resolving_xcode_configuration,
        )
    ])

    return struct(
        args = [_create_arg_env_info(arg) for arg in run["args"]],
        build_targets = build_targets,
        diagnostics = _create_diagnostics_info(run["diagnostics"]),
        env = {
            key: _create_arg_env_info(value)
            for key, value in run["env"].items()
        },
        env_include_default = run["env_include_default"],
        launch_target = launch_target,
        xcode_configuration = xcode_configuration,
    )

def _create_scheme_info(scheme, *, default_xcode_configuration, top_level_deps):
    run = _create_run_info(
        scheme["run"],
        default_xcode_configuration = default_xcode_configuration,
        top_level_deps = top_level_deps,
    )

    return struct(
        name = scheme["name"],
        profile = _create_profile_info(
            scheme["profile"],
            default_xcode_configuration = default_xcode_configuration,
            run = run,
            top_level_deps = top_level_deps,
        ),
        run = run,
        test = _create_test_info(
            scheme["test"],
            default_xcode_configuration = default_xcode_configuration,
            top_level_deps = top_level_deps,
        ),
    )

def _create_test_info(test, *, default_xcode_configuration, top_level_deps):
    if not test:
        return struct(
            args = [],
            build_targets = [],
            diagnostics = _create_diagnostics_info(None),
            env = {},
            env_include_default = False,
            test_targets = [],
            use_run_args_and_env = True,
            xcode_configuration = EMPTY_STRING,
        )

    xcode_configuration = test["xcode_configuration"]
    resolving_xcode_configuration = (
        xcode_configuration or
        default_xcode_configuration
    )

    build_targets = []
    test_targets = []
    for test_target in test["test_targets"]:
        (test_target, test_build_targets) = _create_test_target_info(
            test_target,
            top_level_deps = top_level_deps,
            xcode_configuration = resolving_xcode_configuration,
        )
        build_targets.extend(test_build_targets)
        test_targets.append(test_target)

    build_targets.extend([
        info
        for build_target in test["build_targets"]
        for info in _create_build_target_infos(
            build_target,
            top_level_deps = top_level_deps,
            xcode_configuration = resolving_xcode_configuration,
        )
    ])

    return struct(
        args = [_create_arg_env_info(arg) for arg in test["args"]],
        build_targets = build_targets,
        diagnostics = _create_diagnostics_info(test["diagnostics"]),
        env = {
            key: _create_arg_env_info(value)
            for key, value in test["env"].items()
        },
        env_include_default = test["env_include_default"],
        test_targets = test_targets,
        use_run_args_and_env = test["use_run_args_and_env"],
        xcode_configuration = xcode_configuration,
    )

def _create_test_target_info(
        test_target,
        *,
        top_level_deps,
        xcode_configuration):
    if type(test_target) == "string":
        return (
            struct(
                enabled = True,
                id = _get_top_level_id(
                    target_environment = None,
                    top_level_deps = top_level_deps,
                    top_level_label = test_target,
                    xcode_configuration = xcode_configuration,
                ),
                post_actions = [],
                pre_actions = [],
            ),
            [],
        )

    target_ids = _get_target_ids(
        target_environment = test_target["target_environment"],
        top_level_deps = top_level_deps,
        top_level_label = test_target["label"],
        xcode_configuration = xcode_configuration,
    )

    test_target_info = struct(
        enabled = True,
        id = target_ids.id,
        post_actions = _create_pre_post_action_infos(
            test_target["post_actions"]
        ),
        pre_actions = _create_pre_post_action_infos(
            test_target["pre_actions"]
        ),
    )

    library_targets = [
        _create_library_target_info(
            library_target,
            target_ids = target_ids.deps,
        )
        for library_target in test_target["library_targets"]
    ]

    return (test_target_info, library_targets)


def _get_library_target_id(label, *, target_ids):
    target_id = target_ids.get(label)
    if not target_id:
        fail("""\
Unknown library target in `xcscheme`: {label}

Is '{label}' an `alias` target? Only actual target labels are support in \
`xcscheme` definitions. Check that '{label}' is spelled correctly, and if it \
is, make sure it's a transitive dependency of a top-level target in the \
`xcodeproj.top_level_targets` attribute.
"""
        )

    return target_id

def _get_target_ids(
        *,
        target_environment,
        top_level_deps,
        top_level_label,
        xcode_configuration):
    target_ids_by_configuration = (
        top_level_deps[target_environment or "simulator"]
    )
    target_ids_by_label = target_ids_by_configuration.get(xcode_configuration)
    if not target_ids_by_label:
        fail("""\
Unknown Xcode configuration in `xcscheme`: {}
""".format(xcode_configuration)
        )

    target_ids = target_ids_by_label.get(top_level_label)
    if not target_ids:
        fail("""\
Unknown top-level target in `xcscheme`: {label}

Is '{label}' an `alias` target? Only actual target labels are support in \
`xcscheme` definitions. Check that '{label}' is spelled correctly, and if it \
is, make sure it's in the `xcodeproj.top_level_targets` attribute.
""".format(label = top_level_label)
        )

    return target_ids

def _get_top_level_id(
        *,
        target_environment,
        top_level_deps,
        top_level_label,
        xcode_configuration):
    target_ids = _get_target_ids(
        target_environment = target_environment,
        top_level_deps = top_level_deps,
        top_level_label = top_level_label,
        xcode_configuration = xcode_configuration,
    )
    return target_ids.id

# API

xcschemes_internal = struct(
    create_infos = _create_infos,
    resolve_labels = _resolve_labels,
)

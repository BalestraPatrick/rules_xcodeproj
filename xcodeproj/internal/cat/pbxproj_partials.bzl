"""Actions for creating `PBXProj` partials."""

load("//xcodeproj/internal:collections.bzl", "uniq")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_LIST",
    "EMPTY_STRING",
)
load(
    "//xcodeproj/internal:pbxproj_partials.bzl",
    _pbxproj_partials = "pbxproj_partials",
)
load(":platforms.bzl", "PLATFORM_NAME", "platforms")

# Utility

_SWIFTUI_PREVIEW_PRODUCT_TYPES = {
    "A": None,  # com.apple.product-type.application.on-demand-install-capable
    "B": None,  # com.apple.product-type.bundle
    "E": None,  # com.apple.product-type.extensionkit-extension
    "T": None,  # com.apple.product-type.tool
    "a": None,  # com.apple.product-type.application
    "e": None,  # com.apple.product-type.app-extension
    "f": None,  # com.apple.product-type.framework
    "t": None,  # com.apple.product-type.tv-app-extension
    "u": None,  # com.apple.product-type.bundle.unit-test
    "w": None,  # com.apple.product-type.application.watchapp2
}

def _apple_platform_to_platform_name(platform):
    return PLATFORM_NAME[platform]

def _build_setting_dirname(file):
    path = file.dirname
    if path.startswith("bazel-out/"):
        return "$(BAZEL_OUT){}".format(path[9:])
    if path.startswith("external/"):
        return "$(BAZEL_EXTERNAL){}".format(path[8:])
    if path.startswith("../"):
        return "$(BAZEL_EXTERNAL){}".format(path[2:])
    if path.startswith("/"):
        return path
    return "$(SRCROOT)/{}".format(path)

def _to_binary_bool(bool):
    return "1" if bool else "0"

def _filter_external_file(file):
    if not file.owner.workspace_name:
        return None

    # Removing "external" prefix
    return "$(BAZEL_EXTERNAL){}".format(file.path[8:])

def _filter_external_file_path(file_path):
    if not file_path.startswith("external/"):
        return None

    # Removing "external" prefix
    return "$(BAZEL_EXTERNAL){}".format(file_path[8:])

def _filter_generated_file(file):
    if file.is_source:
        return None

    # Removing "bazel-out" prefix
    return "$(BAZEL_OUT){}".format(file.path[9:])

def _filter_generated_file_path(file_path):
    if not file_path.startswith("bazel-out/"):
        return None

    # Removing "bazel-out" prefix
    return "$(BAZEL_OUT){}".format(file_path[9:])

def _depset_len(d):
    return str(len(d.to_list()))

def _depset_to_list(d):
    return d.to_list()

def _depset_to_paths(d):
    return [file.path for file in d.to_list()]

def _hosted_target(hosted_target):
    return [hosted_target.hosted, hosted_target.host]

def _identity(seq):
    return seq

def _is_same_platform_swiftui_preview_target(*, platform, xcode_target):
    if not xcode_target:
        return False
    if not platforms.is_same_type(platform, xcode_target.platform):
        return False
    return xcode_target.product.type in _SWIFTUI_PREVIEW_PRODUCT_TYPES

def _keys_and_files(pair):
    key, file = pair
    return [key, file.path]

def _null_newlines(str):
    return str.replace("\n", "\0")

# Partials

# enum of flags, mainly to ensure the strings are frozen and reused
_flags = struct(
    additional_target_counts = "--additional-target-counts",
    additional_targets = "--additional-targets",
    archs = "--archs",
    arg_counts = "--arg-counts",
    args_separator = "---",
    args_targets = "--args-targets",
    c_params = "--c-params",
    colorize = "--colorize",
    consolidation_map_output_paths = "--consolidation-map-output-paths",
    consolidation_maps = "--consolidation-maps",
    custom_schemes = "--s",
    cxx_params = "--cxx-params",
    default_xcode_configuration = "--default-xcode-configuration",
    dependencies = "--dependencies",
    dependency_counts = "--dependency-counts",
    dsym_paths = "--dsym-paths",
    env_counts = "--env-counts",
    env_targets = "--env-targets",
    execution_action_actions = "--execution-action-actions",
    execution_action_is_pre_actions = "--execution-action-is-pre-actions",
    execution_action_orders = "--execution-action-orders",
    execution_action_targets = "--execution-action-targets",
    execution_actions = "--e",
    organization_name = "--organization-name",
    os_versions = "--os-versions",
    package_bin_dirs = "--package-bin-dirs",
    post_build_script = "--post-build-script",
    pre_build_script = "--pre-build-script",
    profile_build_only_target_counts = "--profile-build-target-counts",
    profile_build_only_targets = "--profile-build-targets",
    profile_command_line_argument_counts = (
        "--profile-command-line-argument-counts"
    ),
    profile_command_line_argument_enabled_states = (
        "--profile-command-line-argument-enabled-states"
    ),
    profile_environment_variable_counts = (
        "--profile-environment-variable-counts"
    ),
    profile_environment_variable_enabled_states = (
        "--profile-environment-variable-enabled-states"
    ),
    profile_environment_variables_include_defaults = (
        "--profile-environment-variables-include-defaults"
    ),
    profile_launch_extension_hosts = "--profile-launch-extension-hosts",
    profile_launch_targets = "--profile-launch-targets",
    profile_use_run_args_and_env_enabled_states = (
        "--profile-use-run-args-and-env-enabled-states"
    ),
    profile_working_directories = "--profile-working-directories",
    profile_xcode_configurations = "--profile-xcode-configurations",
    resources = "--resources",
    resources_counts = "--resources-counts",
    run_address_sanitizer_enabled_states = (
        "--run-address-sanitizer-enabled-states"
    ),
    run_build_only_target_counts = "--run-build-target-counts",
    run_build_only_targets = "--run-build-targets",
    run_command_line_argument_counts = "--run-command-line-argument-counts",
    run_command_line_argument_enabled_states = (
        "--run-command-line-argument-enabled-states"
    ),
    run_environment_variable_counts = "--run-environment-variable-counts",
    run_environment_variable_enabled_states = (
        "--run-environment-variable-enabled-states"
    ),
    run_environment_variables_include_defaults = (
        "--run-environment-variables-include-defaults"
    ),
    run_launch_extension_hosts = "--run-launch-extension-hosts",
    run_launch_targets = "--run-launch-targets",
    run_thread_sanitizer_enabled_states = (
        "--run-thread-sanitizer-enabled-states"
    ),
    run_ub_sanitizer_enabled_states = "--run-ub-sanitizer-enabled-states",
    run_working_directories = "--run-working-directories",
    run_xcode_configurations = "--run-xcode-configurations",
    target_and_extension_hosts = "--target-and-extension-hosts",
    test_address_sanitizer_enabled_states = (
        "--test-address-sanitizer-enabled-states"
    ),
    test_build_only_target_counts = "--test-build-target-counts",
    test_build_only_targets = "--test-build-targets",
    test_command_line_argument_counts = "--test-command-line-argument-counts",
    test_command_line_argument_enabled_states = (
        "--test-command-line-argument-enabled-states"
    ),
    test_environment_variable_counts = "--test-environment-variable-counts",
    test_environment_variable_enabled_states = (
        "--test-environment-variable-enabled-states"
    ),
    test_environment_variables_include_defaults = (
        "--test-environment-variables-include-defaults"
    ),
    test_target_counts = "--test-target-counts",
    test_target_enabled_states = "--test-target-enabled-states",
    test_targets = "--test-targets",
    test_thread_sanitizer_enabled_states = (
        "--test-thread-sanitizer-enabled-states"
    ),
    test_ub_sanitizer_enabled_states = "--test-ub-sanitizer-enabled-states",
    test_use_run_args_and_env_enabled_states = (
        "--test-use-run-args-and-env-enabled-states"
    ),
    test_xcode_configurations = "--test-xcode-configurations",
    use_base_internationalization = "--use-base-internationalization",
)

_execution_action_name = struct(
    build = "build",
    profile = "profile",
    run = "run",
    test = "test",
)

def _write_swift_debug_settings(
        *,
        actions,
        colorize,
        generator_name,
        install_path,
        tool,
        top_level_swift_debug_settings,
        xcode_configuration):
    output = actions.declare_file(
        "{}_swift_debug_settings/{}-swift_debug_settings.py".format(
            generator_name,
            xcode_configuration,
        ),
    )

    args = actions.args()

    # colorize
    args.add("1" if colorize else "0")

    # outputPath
    args.add(output)

    # keysAndFiles
    args.add_all(top_level_swift_debug_settings, map_each = _keys_and_files)

    message = "Generating {} {}-swift_debug_settings.py".format(
        install_path,
        xcode_configuration,
    )

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
            file
            for _, file in top_level_swift_debug_settings
        ],
        outputs = [output],
        progress_message = message,
        mnemonic = "WriteSwiftDebugSettings",
    )

    return output

def _write_target_build_settings(
        *,
        actions,
        apple_generate_dsym,
        certificate_name = None,
        colorize,
        conly_args,
        cxx_args,
        device_family = EMPTY_STRING,
        entitlements = None,
        extension_safe = False,
        generate_build_settings,
        include_self_swift_debug_settings = True,
        infoplist = None,
        is_top_level_target = False,
        name,
        package_bin_dir,
        previews_dynamic_frameworks = EMPTY_LIST,
        previews_include_path = EMPTY_STRING,
        provisioning_profile_is_xcode_managed = False,
        provisioning_profile_name = None,
        skip_codesigning = False,
        swift_args,
        swift_debug_settings_to_merge,
        team_id = None,
        tool):
    """Creates the `OTHER_SWIFT_FLAGS` build setting string file for a target.

    Args:
        actions: `ctx.actions`.
        apple_generate_dsym: `cpp_fragment.apple_generate_dsym`.
        colorize: A `bool` indicating whether to colorize the output.
        conly_args: A `list` of `Args` for the C compile action for this target.
        cxx_args: A `list` of `Args` for the C++ compile action for this target.
        device_family: A value as returned by `get_targeted_device_family`.
        entitlements: An optional entitlements `File`.
        extension_safe: If `True, `APPLICATION_EXTENSION_API_ONLY` will be set.
        infoplist: An optional `File` containing the `Info.plist` for the
            target.
        name: The name of the target.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        skip_codesigning: If `True`, `CODE_SIGNING_ALLOWED = NO` will be set.
        swift_args: A `list` of `Args` for the `SwiftCompile` action for this
            target.
        swift_debug_settings_to_merge: A `depset` of `Files` containing
            Swift debug settings from dependencies.
        swiftmodule: `target_outputs.direct_outputs.swift.,module.swiftmodule`.
        tool: The executable that will generate the output files.

    Returns:
        A `tuple` with two elements:

        *   A `File` containing TBD.
        *   A `list` of `File`s containing C or C++ compiler arguments. These
            files should be added to compile outputs groups to ensure that Xcode
            has them available for the `Create Compile Dependencies` build
            phase.
    """
    generate_swift_debug_settings = swift_args or is_top_level_target

    if not (generate_build_settings or generate_swift_debug_settings):
        return None, None, []

    params = []

    args = actions.args()

    # colorize
    args.add("1" if colorize else "0")

    if generate_build_settings:
        build_settings_output = actions.declare_file(
            "{}.rules_xcodeproj.target_build_settings".format(name),
        )

        # buildSettingsOutputPath
        args.add(build_settings_output)
    else:
        build_settings_output = None

        # buildSettingsOutputPath
        args.add("")

    if swift_args or is_top_level_target:
        debug_settings_output = actions.declare_file(
            "{}.rules_xcodeproj.debug_settings".format(name),
        )

        # swiftDebugSettingsOutputPath
        args.add(debug_settings_output)

        # includeSelfSwiftDebugSettings
        args.add("1" if include_self_swift_debug_settings else "0")

        # transitiveSwiftDebugSettingPaths
        args.add_all(
            swift_debug_settings_to_merge,
            omit_if_empty = False,
            terminate_with = _flags.args_separator,
        )

        inputs = swift_debug_settings_to_merge
    else:
        debug_settings_output = None

        # swiftDebugSettingsOutputPath
        args.add("")

        inputs = []

    # deviceFamily
    args.add(device_family)

    # extensionSafe
    args.add("1" if extension_safe else "0")

    # generatesDsyms
    args.add("1" if apple_generate_dsym else "0")

    # infoPlist
    args.add(infoplist or EMPTY_STRING)

    # entitlements
    args.add(entitlements or EMPTY_STRING)

    # skipCodesigning
    args.add("1" if skip_codesigning else "0")

    # certificateName
    args.add(certificate_name or EMPTY_STRING)

    # provisioningProfileName
    args.add(provisioning_profile_name or EMPTY_STRING)

    # teamID
    args.add(team_id or EMPTY_STRING)

    # provisioningProfileIsXcodeManaged
    args.add("1" if provisioning_profile_is_xcode_managed else "0")

    # packageBinDir
    args.add(package_bin_dir)

    # previewFrameworkPaths
    args.add_joined(
        previews_dynamic_frameworks,
        format_each = '"%s"',
        map_each = _build_setting_dirname,
        omit_if_empty = False,
        join_with = " ",
    )

    # previewsIncludePath
    args.add(previews_include_path)

    c_output_args = actions.args()

    # C argsSeparator
    c_output_args.add(_flags.args_separator)

    if generate_build_settings and conly_args:
        c_params = actions.declare_file(
            "{}.c.compile.params".format(name),
        )
        params.append(c_params)

        # cParams
        c_output_args.add(c_params)

    cxx_output_args = actions.args()

    # Cxx argsSeparator
    cxx_output_args.add(_flags.args_separator)

    if generate_build_settings and cxx_args:
        cxx_params = actions.declare_file(
            "{}.cxx.compile.params".format(name),
        )
        params.append(cxx_params)

        # cxxParams
        cxx_output_args.add(cxx_params)

    outputs = params
    if build_settings_output:
        outputs.append(build_settings_output)
    if debug_settings_output:
        outputs.append(debug_settings_output)

    actions.run(
        arguments = (
            [args] + swift_args + [c_output_args] + conly_args +
            [cxx_output_args] + cxx_args
        ),
        executable = tool,
        inputs = inputs,
        outputs = outputs,
        progress_message = "Generating %{output}",
        mnemonic = "WriteTargetBuildSettings",
    )

    return build_settings_output, debug_settings_output, params

def _write_schemes(
        *,
        actions,
        autogeneration_mode,
        colorize,
        consolidation_maps,
        default_xcode_configuration,
        extension_point_identifiers_file,
        generator_name,
        hosted_targets,
        include_transitive_previews_targets,
        install_path,
        targets_args,
        targets_env,
        tool,
        workspace_directory,
        xcode_targets,
        xcscheme_infos):
    """Creates the `.xcscheme` `File`s for a project.

    Args:
        actions: `ctx.actions`.
        autogeneration_mode: Specifies how Xcode schemes are automatically
            generated.
        colorize: A `bool` indicating whether to colorize the output.
        consolidation_maps: A `list` of `File`s containing target consolidation
            maps.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        extension_point_identifiers_file: A `File` that contains a JSON
            representation of `[TargetID: ExtensionPointIdentifier]`.
        generator_name: The name of the `xcodeproj` generator target.
        hosted_targets: A `depset` of `struct`s with `host` and `hosted` fields.
            The `host` field is the target ID of the hosting target. The
            `hosted` field is the target ID of the hosted target.
        include_transitive_previews_targets: Whether to adjust schemes to
            explicitly include transitive dependencies that are able to run
            SwiftUI Previews.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        targets_args: A `dict` mapping `xcode_target.id` to `list` of
            command-line arguments.
        targets_env: A `dict` mapping `xcode_target.id` to `dict` of environment
            variables.
        tool: The executable that will generate the output files.
        workspace_directory: The absolute path to the Bazel workspace
            directory.
        xcode_targets: A `dict` mapping `xcode_target.id` to `xcode_target`s.
        xcscheme_infos: A `list` of `struct`s as returned` by
            `xcschemes_internal.create_infos`.

    Returns:
        A `tuple` with two elements:

        *   A `File` for the directory containing the `.xcscheme`s.
        *   The `xcschememanagement.plist` `File`.
    """
    additional_targets = []
    additional_target_counts = []
    for xcode_target in xcode_targets.values():
        if (include_transitive_previews_targets and
            xcode_target.product.type in _SWIFTUI_PREVIEW_PRODUCT_TYPES):
            ids = [
                id
                for id in xcode_target.transitive_dependencies.to_list()
                if _is_same_platform_swiftui_preview_target(
                    platform = xcode_target.platform,
                    xcode_target = xcode_targets.get(id),
                )
            ]
            if ids:
                additional_targets.append(xcode_target.id)
                additional_targets.extend(ids)
                additional_target_counts.append(len(ids))

    output = actions.declare_directory(
        "{}_pbxproj_partials/xcschemes".format(generator_name),
    )
    xcschememanagement = actions.declare_file(
        "{}_pbxproj_partials/xcschememanagement.plist".format(generator_name),
    )

    execution_actions_file = actions.declare_file(
        "{}_pbxproj_partials/execution_actions_file".format(generator_name),
    )
    targets_args_env_file = actions.declare_file(
        "{}_pbxproj_partials/targets_args_env_file".format(generator_name),
    )
    schemes_args_env_file = actions.declare_file(
        "{}_pbxproj_partials/schemes_args_env_file".format(generator_name),
    )

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    execution_actions_args = actions.args()
    execution_actions_args.set_param_file_format("multiline")

    targets_args_env_args = actions.args()
    targets_args_env_args.set_param_file_format("multiline")

    schemes_args_env_args = actions.args()
    schemes_args_env_args.set_param_file_format("multiline")

    # outputDirectory
    args.add(output.path)

    # schemeManagementOutputPath
    args.add(xcschememanagement)

    # autogenerationMode
    args.add(autogeneration_mode)

    # defaultXcodeConfiguration
    args.add(default_xcode_configuration)

    # workspace
    args.add(workspace_directory)

    # installPath
    args.add(install_path)

    # extensionPointIdentifiersFile
    args.add(extension_point_identifiers_file)

    # executionActionsFile
    args.add(execution_actions_file)

    # targetsArgsEnvFile
    args.add(targets_args_env_file)

    # schemesArgsEnvFile
    args.add(schemes_args_env_file)

    # consolidationMaps
    args.add_all(_flags.consolidation_maps, consolidation_maps)

    # targetAndExtensionHosts
    args.add_all(
        _flags.target_and_extension_hosts,
        hosted_targets,
        map_each = _hosted_target,
    )

    if additional_targets:
        args.add_all(_flags.additional_targets, additional_targets)
        args.add_all(
            _flags.additional_target_counts,
            additional_target_counts,
        )

    arg_counts = []
    args_targets = []
    targets_args_list = []
    for id, target_args in targets_args.items():
        args_targets.append(id)
        arg_counts.append(len(target_args))
        targets_args_list.extend(target_args)

    # argsTargets
    args.add_all(_flags.args_targets, args_targets)

    # argCounts
    args.add_all(_flags.arg_counts, arg_counts)

    # args
    targets_args_env_args.add_all(targets_args_list)

    env_counts = []
    env_targets = []
    targets_env_list = []
    for id, target_env in targets_env.items():
        env_targets.append(id)
        env_counts.append(len(target_env))
        for k, v in target_env:
            targets_env_list.append(k)
            targets_env_list.append(v)

    # envTargets
    args.add_all(_flags.env_targets, env_targets)

    # envCounts
    args.add_all(_flags.env_counts, env_counts)

    # env
    targets_args_env_args.add_all(targets_env_list)

    execution_action_actions = []
    execution_actions_args_list = []
    execution_action_is_pre_actions = []
    execution_action_orders = []
    execution_action_scheme_names = []
    execution_action_targets = []
    # buildifier: disable=uninitialized
    def _add_execution_action(
            action,
            *,
            action_name,
            id,
            is_pre_action,
            scheme_name):
        execution_actions_args_list.append(action.title)
        execution_actions_args_list.append(action.script_text)
        execution_action_scheme_names.append(scheme_name)
        execution_action_is_pre_actions.append(is_pre_action)
        execution_action_targets.append(id)
        execution_action_orders.append(action.order or "")

        if action.for_build:
            execution_action_actions.append(_execution_action_name.build)
        else:
            execution_action_actions.append(action_name)

    profile_build_only_target_counts = []
    profile_build_only_targets = []
    profile_command_line_argument_counts = []
    profile_command_line_argument_enabled_states = []
    profile_environment_variable_counts = []
    profile_environment_variable_enabled_states = []
    profile_environment_variables_include_defaults = []
    profile_launch_extension_hosts = []
    profile_launch_targets = []
    profile_use_run_args_and_env_enabled_states = []
    profile_working_directories = []
    profile_xcode_configurations = []
    run_address_sanitizer_enabled_states = []
    run_build_only_target_counts = []
    run_build_only_targets = []
    run_command_line_argument_counts = []
    run_command_line_argument_enabled_states = []
    run_environment_variable_counts = []
    run_environment_variable_enabled_states = []
    run_environment_variables_include_defaults = []
    run_launch_extension_hosts = []
    run_launch_targets = []
    run_thread_sanitizer_enabled_states = []
    run_ub_sanitizer_enabled_states = []
    run_working_directories = []
    run_xcode_configurations = []
    scheme_names = []
    test_address_sanitizer_enabled_states = []
    test_build_only_target_counts = []
    test_build_only_targets = []
    test_command_line_argument_counts = []
    test_command_line_argument_enabled_states = []
    test_environment_variable_counts = []
    test_environment_variable_enabled_states = []
    test_environment_variables_include_defaults = []
    test_target_counts = []
    test_target_enabled_states = []
    test_targets = []
    test_thread_sanitizer_enabled_states = []
    test_thread_sanitizer_enabled_states = []
    test_ub_sanitizer_enabled_states = []
    test_use_run_args_and_env_enabled_states = []
    test_xcode_configurations = []
    for info in xcscheme_infos:
        scheme_name = info.name
        scheme_names.append(scheme_name)

        test_target_counts.append(len(info.test.test_targets))
        for test_target in info.test.test_targets:
            id = test_target.id
            test_targets.append(id)
            test_target_enabled_states.append(test_target.enabled)
            for action in test_target.pre_actions:
                _add_execution_action(
                    action,
                    action_name = _execution_action_name.test,
                    id = id,
                    is_pre_action = True,
                    scheme_name = scheme_name,
                )
            for action in test_target.post_actions:
                _add_execution_action(
                    action,
                    action_name = _execution_action_name.test,
                    id = id,
                    is_pre_action = False,
                    scheme_name = scheme_name,
                )

        test_build_only_target_counts.append(len(info.test.build_targets))
        for build_only_target in info.test.build_targets:
            id = build_only_target.id
            test_build_only_targets.append(id)
            for action in build_only_target.pre_actions:
                _add_execution_action(
                    action,
                    action_name = _execution_action_name.test,
                    id = id,
                    is_pre_action = True,
                    scheme_name = scheme_name,
                )
            for action in build_only_target.post_actions:
                _add_execution_action(
                    action,
                    action_name = _execution_action_name.test,
                    id = id,
                    is_pre_action = False,
                    scheme_name = scheme_name,
                )

        test_command_line_argument_counts.append(len(info.test.args))

        test_command_line_arguments = []
        for arg in info.test.args:
            test_command_line_arguments.append(arg.value)
            test_command_line_argument_enabled_states.append(arg.enabled)
        schemes_args_env_args.add_all(
            test_command_line_arguments,
            map_each = _null_newlines,
        )

        test_environment_variables_include_defaults.append(
            info.test.env_include_default,
        )
        test_environment_variable_counts.append(len(info.test.env))

        test_environment_variables = []
        for key, env in info.test.env.items():
            test_environment_variables.append(key)
            test_environment_variables.append(env.value)
            test_environment_variable_enabled_states.append(env.enabled)
        schemes_args_env_args.add_all(
            test_environment_variables,
            map_each = _null_newlines,
        )

        test_address_sanitizer_enabled_states.append(
            info.test.diagnostics.address_sanitizer,
        )
        test_thread_sanitizer_enabled_states.append(
            info.test.diagnostics.thread_sanitizer,
        )
        test_ub_sanitizer_enabled_states.append(
            info.test.diagnostics.undefined_behavior_sanitizer,
        )
        test_use_run_args_and_env_enabled_states.append(
            info.test.use_run_args_and_env,
        )
        test_xcode_configurations.append(info.test.xcode_configuration)

        run_build_only_target_counts.append(len(info.run.build_targets))
        for build_only_target in info.run.build_targets:
            id = build_only_target.id
            run_build_only_targets.append(id)
            for action in build_only_target.pre_actions:
                _add_execution_action(
                    action,
                    action_name = _execution_action_name.run,
                    id = id,
                    is_pre_action = True,
                    scheme_name = scheme_name,
                )
            for action in build_only_target.post_actions:
                _add_execution_action(
                    action,
                    action_name = _execution_action_name.run,
                    id = id,
                    is_pre_action = False,
                    scheme_name = scheme_name,
                )

        run_command_line_argument_counts.append(len(info.run.args))

        run_command_line_arguments = []
        for arg in info.run.args:
            run_command_line_arguments.append(arg.value)
            run_command_line_argument_enabled_states.append(arg.enabled)
        schemes_args_env_args.add_all(
            run_command_line_arguments,
            map_each = _null_newlines,
        )

        run_environment_variables_include_defaults.append(
            info.run.env_include_default,
        )
        run_environment_variable_counts.append(len(info.run.env))

        run_environment_variables = []
        for key, env in info.run.env.items():
            run_environment_variables.append(key)
            run_environment_variables.append(env.value)
            run_environment_variable_enabled_states.append(env.enabled)
        schemes_args_env_args.add_all(
            run_environment_variables,
            map_each = _null_newlines,
        )

        run_address_sanitizer_enabled_states.append(
            info.run.diagnostics.address_sanitizer,
        )
        run_thread_sanitizer_enabled_states.append(
            info.run.diagnostics.thread_sanitizer,
        )
        run_ub_sanitizer_enabled_states.append(
            info.run.diagnostics.undefined_behavior_sanitizer,
        )
        run_launch_extension_hosts.append(
            info.run.launch_target.extension_host,
        )
        run_working_directories.append(
            info.run.launch_target.working_directory,
        )
        run_xcode_configurations.append(info.run.xcode_configuration)

        launch_target_id = info.run.launch_target.id
        run_launch_targets.append(launch_target_id)
        for action in info.run.launch_target.pre_actions:
            _add_execution_action(
                action,
                action_name = _execution_action_name.run,
                id = launch_target_id,
                is_pre_action = True,
                scheme_name = scheme_name,
            )
        for action in info.run.launch_target.post_actions:
            _add_execution_action(
                action,
                action_name = _execution_action_name.run,
                id = launch_target_id,
                is_pre_action = False,
                scheme_name = scheme_name,
            )

        profile_build_only_target_counts.append(len(info.profile.build_targets))
        for build_only_target in info.profile.build_targets:
            id = build_only_target.id
            profile_build_only_targets.append(id)
            for action in build_only_target.pre_actions:
                _add_execution_action(
                    action,
                    action_name = _execution_action_name.profile,
                    id = id,
                    is_pre_action = True,
                    scheme_name = scheme_name,
                )
            for action in build_only_target.post_actions:
                _add_execution_action(
                    action,
                    action_name = _execution_action_name.profile,
                    id = id,
                    is_pre_action = False,
                    scheme_name = scheme_name,
                )

        profile_command_line_argument_counts.append(len(info.profile.args))

        profile_command_line_arguments = []
        for arg in info.profile.args:
            profile_command_line_arguments.append(arg.value)
            profile_command_line_argument_enabled_states.append(arg.enabled)
        schemes_args_env_args.add_all(
            profile_command_line_arguments,
            map_each = _null_newlines,
        )

        profile_environment_variables_include_defaults.append(
            info.profile.env_include_default,
        )
        profile_environment_variable_counts.append(len(info.profile.env))

        profile_environment_variables = []
        for key, env in info.profile.env.items():
            profile_environment_variables.append(key)
            profile_environment_variables.append(env.value)
            profile_environment_variable_enabled_states.append(env.enabled)
        schemes_args_env_args.add_all(
            profile_environment_variables,
            map_each = _null_newlines,
        )

        profile_use_run_args_and_env_enabled_states.append(
            info.profile.use_run_args_and_env,
        )
        profile_launch_extension_hosts.append(
            info.profile.launch_target.extension_host,
        )
        profile_working_directories.append(
            info.profile.launch_target.working_directory,
        )
        profile_xcode_configurations.append(info.profile.xcode_configuration)

        launch_target_id = info.profile.launch_target.id
        profile_launch_targets.append(launch_target_id)
        for action in info.profile.launch_target.pre_actions:
            _add_execution_action(
                action,
                action_name = _execution_action_name.profile,
                id = launch_target_id,
                is_pre_action = True,
                scheme_name = scheme_name,
            )
        for action in info.profile.launch_target.post_actions:
            _add_execution_action(
                action,
                action_name = _execution_action_name.profile,
                id = launch_target_id,
                is_pre_action = False,
                scheme_name = scheme_name,
            )

    execution_actions_args.add_all(
        execution_actions_args_list,
        map_each = _null_newlines,
    )

    # customSchemes
    args.add_all(scheme_names, before_each = _flags.custom_schemes)

    # testBuildTargetCounts
    args.add_all(
        _flags.test_build_only_target_counts,
        test_build_only_target_counts,
    )

    # testBuildTargets
    args.add_all(_flags.test_build_only_targets, test_build_only_targets)

    # testAddressSanitizerEnabledStates
    args.add_all(
        _flags.test_address_sanitizer_enabled_states,
        test_address_sanitizer_enabled_states,
        map_each = _to_binary_bool,
    )

    # testCommandLineArgumentCounts
    args.add_all(
        _flags.test_command_line_argument_counts,
        test_command_line_argument_counts,
    )

    # testCommandLineArgumentEnabledStates
    args.add_all(
        _flags.test_command_line_argument_enabled_states,
        test_command_line_argument_enabled_states,
        map_each = _to_binary_bool,
    )

    # testEnvironmentVariableCounts
    args.add_all(
        _flags.test_environment_variable_counts,
        test_environment_variable_counts,
    )

    # testEnvironmentVariableEnabledStates
    args.add_all(
        _flags.test_environment_variable_enabled_states,
        test_environment_variable_enabled_states,
        map_each = _to_binary_bool,
    )

    # testEnvironmentVariablesIncludeDefaults
    args.add_all(
        _flags.test_environment_variables_include_defaults,
        test_environment_variables_include_defaults,
        map_each = _to_binary_bool,
    )

    # testThreadSanitizerEnableStates
    args.add_all(
        _flags.test_thread_sanitizer_enabled_states,
        test_thread_sanitizer_enabled_states,
        map_each = _to_binary_bool,
    )

    # testUBSanitizerEnableStates
    args.add_all(
        _flags.test_ub_sanitizer_enabled_states,
        test_ub_sanitizer_enabled_states,
        map_each = _to_binary_bool,
    )

    # testTargetCounts
    args.add_all(_flags.test_target_counts, test_target_counts)

    # testTargets
    args.add_all(_flags.test_targets, test_targets)

    # testTargetEnabledStates
    args.add_all(
        _flags.test_target_enabled_states,
        test_target_enabled_states,
        map_each = _to_binary_bool,
    )

    # testUseRunArgsAndEnvEnabledStates
    args.add_all(
        _flags.test_use_run_args_and_env_enabled_states,
        test_use_run_args_and_env_enabled_states,
        map_each = _to_binary_bool,
    )

    # testXcodeConfigurations
    args.add_all(_flags.test_xcode_configurations, test_xcode_configurations)

    # runBuildTargetCounts
    args.add_all(
        _flags.run_build_only_target_counts,
        run_build_only_target_counts,
    )

    # runBuildTargets
    args.add_all(_flags.run_build_only_targets, run_build_only_targets)

    # runCommandLineArgumentCounts
    args.add_all(
        _flags.run_command_line_argument_counts,
        run_command_line_argument_counts,
    )

    # runCommandLineArgumentEnabledStates
    args.add_all(
        _flags.run_command_line_argument_enabled_states,
        run_command_line_argument_enabled_states,
        map_each = _to_binary_bool,
    )

    # runEnvironmentVariableCounts
    args.add_all(
        _flags.run_environment_variable_counts,
        run_environment_variable_counts,
    )

    # runEnvironmentVariableEnabledStates
    args.add_all(
        _flags.run_environment_variable_enabled_states,
        run_environment_variable_enabled_states,
        map_each = _to_binary_bool,
    )

    # runEnvironmentVariablesIncludeDefaults
    args.add_all(
        _flags.run_environment_variables_include_defaults,
        run_environment_variables_include_defaults,
        map_each = _to_binary_bool,
    )

    # runAddressSanitizerEnableStates
    args.add_all(
        _flags.run_address_sanitizer_enabled_states,
        run_address_sanitizer_enabled_states,
        map_each = _to_binary_bool,
    )

    # runThreadSanitizerEnableStates
    args.add_all(
        _flags.run_thread_sanitizer_enabled_states,
        run_thread_sanitizer_enabled_states,
        map_each = _to_binary_bool,
    )

    # runUBSanitizerEnableStates
    args.add_all(
        _flags.run_ub_sanitizer_enabled_states,
        run_ub_sanitizer_enabled_states,
        map_each = _to_binary_bool,
    )

    # runLaunchExtensionHosts
    args.add_all(
        _flags.run_launch_extension_hosts,
        run_launch_extension_hosts,
    )

    # runWorkingDirectories
    args.add_all(_flags.run_working_directories, run_working_directories)

    # runXcodeConfigurations
    args.add_all(_flags.run_xcode_configurations, run_xcode_configurations)

    # runLaunchTargets
    args.add_all(_flags.run_launch_targets, run_launch_targets)

    # profileBuildTargetCounts
    args.add_all(
        _flags.profile_build_only_target_counts,
        profile_build_only_target_counts,
    )

    # profileBuildTargets
    args.add_all(
        _flags.profile_build_only_targets,
        profile_build_only_targets,
    )

    # profileCommandLineArgumentCounts
    args.add_all(
        _flags.profile_command_line_argument_counts,
        profile_command_line_argument_counts,
    )

    # profileCommandLineArgumentEnabledStates
    args.add_all(
        _flags.profile_command_line_argument_enabled_states,
        profile_command_line_argument_enabled_states,
        map_each = _to_binary_bool,
    )

    # profileEnvironmentVariableCounts
    args.add_all(
        _flags.profile_environment_variable_counts,
        profile_environment_variable_counts,
    )

    # profileEnvironmentVariableEnabledStates
    args.add_all(
        _flags.profile_environment_variable_enabled_states,
        profile_environment_variable_enabled_states,
        map_each = _to_binary_bool,
    )

    # profileEnvironmentVariablesIncludeDefaults
    args.add_all(
        _flags.profile_environment_variables_include_defaults,
        profile_environment_variables_include_defaults,
        map_each = _to_binary_bool,
    )

    # profileUseRunArgsAndEnvEnabledStates
    args.add_all(
        _flags.profile_use_run_args_and_env_enabled_states,
        profile_use_run_args_and_env_enabled_states,
        map_each = _to_binary_bool,
    )

    # profileLaunchExtensionHosts
    args.add_all(
        _flags.profile_launch_extension_hosts,
        profile_launch_extension_hosts,
    )

    # profileLaunchTargets
    args.add_all(_flags.profile_launch_targets, profile_launch_targets)

    # profileWorkingDirectories
    args.add_all(
        _flags.profile_working_directories,
        profile_working_directories,
    )

    # profileXcodeConfigurations
    args.add_all(
        _flags.profile_xcode_configurations,
        profile_xcode_configurations,
    )

    # executionActions
    args.add_all(
        execution_action_scheme_names,
        before_each = _flags.execution_actions,
    )

    # executionActionIsPreActions
    args.add_all(
        _flags.execution_action_is_pre_actions,
        execution_action_is_pre_actions,
        map_each = _to_binary_bool,
    )

    # executionActionActions
    args.add_all(_flags.execution_action_actions, execution_action_actions)

    # executionActionTargets
    args.add_all(_flags.execution_action_targets, execution_action_targets)

    # executionActionOrders
    args.add_all(_flags.execution_action_orders, execution_action_orders)

    # colorize
    if colorize:
        args.add(_flags.colorize)

    actions.write(execution_actions_file, execution_actions_args)
    actions.write(targets_args_env_file, targets_args_env_args)
    actions.write(schemes_args_env_file, schemes_args_env_args)

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
            extension_point_identifiers_file,
            execution_actions_file,
            targets_args_env_file,
            schemes_args_env_file,
        ] + consolidation_maps,
        outputs = [output, xcschememanagement],
        progress_message = "Creating '.xcschemes` for {}".format(install_path),
        mnemonic = "WriteXCSchemes",
        execution_requirements = {
            # Lots of files to read and write, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return (output, xcschememanagement)

def _write_targets(
        *,
        actions,
        colorize,
        consolidation_maps,
        default_xcode_configuration,
        generator_name,
        install_path,
        link_params,
        tool,
        xcode_target_configurations,
        xcode_targets,
        xcode_targets_by_label):
    """Creates `File`s representing targets in a `PBXProj` element.

    Args:
        actions: `ctx.actions`.
        colorize: Whether to colorize the output.
        consolidation_maps: A `dict` mapping `File`s containing target
            consolidation maps to a `list` of `Label`s of the targets included
            in the map.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        generator_name: The name of the `xcodeproj` generator target.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        link_params: A `dict` mapping `xcode_target.id` to a `link.params` file
            for that target, if one is needed.
        tool: The executable that will generate the output files.
        xcode_target_configurations: A `dict` mapping `xcode_target.id` to a
            `list` of Xcode configuration names that the target is present in.
        xcode_targets: A `dict` mapping `xcode_target.id` to `xcode_target`s.
        xcode_targets_by_label: A `dict` mapping `xcode_target.label` to a
            `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A tuple with two elements:

        *   `pbxnativetargets`: A `list` of `File`s for the `PBNativeTarget`
            `PBXProj` partials.
        *   `buildfile_subidentifiers_files`: A `list` of `File`s that contain
            serialized `[Identifiers.BuildFile.SubIdentifier]`s.
    """
    pbxnativetargets = []
    buildfile_subidentifiers_files = []
    for consolidation_map, labels in consolidation_maps.items():
        (
            label_pbxnativetargets,
            label_buildfile_subidentifiers,
        ) = _write_consolidation_map_targets(
            actions = actions,
            colorize = colorize,
            consolidation_map = consolidation_map,
            default_xcode_configuration = default_xcode_configuration,
            generator_name = generator_name,
            idx = consolidation_map.basename,
            install_path = install_path,
            labels = labels,
            link_params = link_params,
            tool = tool,
            xcode_target_configurations = xcode_target_configurations,
            xcode_targets = xcode_targets,
            xcode_targets_by_label = xcode_targets_by_label,
        )

        pbxnativetargets.append(label_pbxnativetargets)
        buildfile_subidentifiers_files.append(label_buildfile_subidentifiers)

    return (
        pbxnativetargets,
        buildfile_subidentifiers_files,
    )

def _dsym_files_to_string(dsym_files):
    dsym_paths = []
    for file in dsym_files.to_list():
        file_path = file.path

        # dSYM files contain plist and DWARF.
        if not file_path.endswith("Info.plist"):
            # ../Product.dSYM/Contents/Resources/DWARF/Product
            dsym_path = "/".join(file_path.split("/")[:-4])
            dsym_paths.append("\"{}\"".format(dsym_path))
    return " ".join(dsym_paths)

_UNIT_TEST_PRODUCT_TYPE = "u"  # com.apple.product-type.bundle.unit-test

def _write_consolidation_map_targets(
        *,
        actions,
        apple_platform_to_platform_name = _apple_platform_to_platform_name,
        colorize,
        consolidation_map,
        default_xcode_configuration,
        generator_name,
        idx,
        install_path,
        labels,
        link_params,
        tool,
        xcode_target_configurations,
        xcode_targets,
        xcode_targets_by_label):
    """Creates `File`s representing targets in a `PBXProj` element, for a \
    given consolidation map

    Args:
        actions: `ctx.actions`.
        apple_platform_to_platform_name: Exposed for testing. Don't set.
        colorize: Whether to colorize the output.
        consolidation_map: A `File` containing a target consolidation maps.
        default_xcode_configuration: The name of the the Xcode configuration to
            use when building, if not overridden by custom schemes.
        generator_name: The name of the `xcodeproj` generator target.
        idx: The index of the consolidation map.
        install_path: The workspace relative path to where the final
            `.xcodeproj` will be written.
        link_params: A `dict` mapping `xcode_target.id` to a `link.params` file
            for that target, if one is needed.
        labels: A `list` of `Label`s of the targets included in
            `consolidation_map`.
        tool: The executable that will generate the output files.
        xcode_target_configurations: A `dict` mapping `xcode_target.id` to a
            `list` of Xcode configuration names that the target is present in.
        xcode_targets: A `dict` mapping `xcode_target.id` to `xcode_target`s.
        xcode_targets_by_label: A `dict` mapping `xcode_target.label` to a
            `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A tuple with two elements:

        *   `pbxnativetargets`: A `File` for the `PBNativeTarget` `PBXProj`
            partial.
        *   `buildfile_subidentifiers`: A `File` that contain serialized
            `[Identifiers.BuildFile.SubIdentifier]`.
    """
    pbxnativetargets = actions.declare_file(
        "{}_pbxproj_partials/pbxnativetargets/{}".format(
            generator_name,
            idx,
        ),
    )
    buildfile_subidentifiers = actions.declare_file(
        "{}_pbxproj_partials/buildfile_subidentifiers/{}".format(
            generator_name,
            idx,
        ),
    )

    target_arguments_file = actions.declare_file(
        "{}_pbxproj_partials/target_arguments_files/{}".format(
            generator_name,
            idx,
        ),
    )
    top_level_target_attributes_file = actions.declare_file(
        "{}_pbxproj_partials/top_level_target_attributes_files/{}".format(
            generator_name,
            idx,
        ),
    )
    unit_test_host_attributes_file = actions.declare_file(
        "{}_pbxproj_partials/unit_test_host_attributes_files/{}".format(
            generator_name,
            idx,
        ),
    )

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # targetsOutputPath
    args.add(pbxnativetargets)

    # buildFileSubIdentifiersOutputPath
    args.add(buildfile_subidentifiers)

    # consolidationMap
    args.add(consolidation_map)

    # targetArgumentsFile
    args.add(target_arguments_file)

    # topLevelTargetAttributesFile
    args.add(top_level_target_attributes_file)

    # unitTestHostAttributesFile
    args.add(unit_test_host_attributes_file)

    # defaultXcodeConfiguration
    args.add(default_xcode_configuration)

    # Target arguments

    targets_args = actions.args()
    targets_args.set_param_file_format("multiline")

    top_level_targets_args = actions.args()
    top_level_targets_args.set_param_file_format("multiline")

    unit_test_hosts_args = actions.args()
    unit_test_hosts_args.set_param_file_format("multiline")

    target_count = 0
    for label in labels:
        target_count += len(xcode_targets_by_label[label])

    targets_args.add(target_count)

    build_settings_files = []
    unit_test_host_ids = []
    for label in labels:
        for xcode_target in xcode_targets_by_label[label].values():
            targets_args.add(xcode_target.id)
            targets_args.add(xcode_target.product.type)
            targets_args.add(xcode_target.package_bin_dir)
            targets_args.add(xcode_target.product.name)
            targets_args.add(xcode_target.product.basename)

            # FIXME: Don't send if it would be the same as `$(PRODUCT_NAME:c99extidentifier)`?
            targets_args.add(xcode_target.module_name)

            targets_args.add(
                apple_platform_to_platform_name(xcode_target.platform.platform),
            )
            targets_args.add(xcode_target.platform.os_version)
            targets_args.add(xcode_target.platform.arch)
            targets_args.add(
                _dsym_files_to_string(xcode_target.outputs.dsym_files),
            )

            if (xcode_target.test_host and
                xcode_target.product.type == _UNIT_TEST_PRODUCT_TYPE):
                unit_test_host = xcode_target.test_host
                unit_test_host_ids.append(unit_test_host)
            else:
                unit_test_host = EMPTY_STRING

            build_settings_file = (
                xcode_target.build_settings_file
            )
            targets_args.add(build_settings_file or EMPTY_STRING)
            if build_settings_file:
                build_settings_files.append(
                    build_settings_file,
                )

            targets_args.add("1" if xcode_target.has_c_params else "0")
            targets_args.add("1" if xcode_target.has_cxx_params else "0")

            targets_args.add_all(
                xcode_target.inputs.srcs,
                omit_if_empty = False,
                terminate_with = "--",
            )
            targets_args.add_all(
                xcode_target.inputs.non_arc_srcs,
                omit_if_empty = False,
                terminate_with = "--",
            )
            targets_args.add_all(
                xcode_target.inputs.resources,
                omit_if_empty = False,
                terminate_with = "--",
            )
            targets_args.add_all(
                xcode_target.inputs.folder_resources,
                omit_if_empty = False,
                terminate_with = "--",
            )
            targets_args.add_all(
                xcode_target_configurations[xcode_target.id],
                omit_if_empty = False,
                terminate_with = "--",
            )

            # FIXME: Only set for top level targets
            if xcode_target.outputs.product_path:
                top_level_targets_args.add(xcode_target.id)
                top_level_targets_args.add(
                    xcode_target.bundle_id or EMPTY_STRING,
                )
                top_level_targets_args.add(
                    xcode_target.outputs.product_path or EMPTY_STRING,
                )
                top_level_targets_args.add(
                    link_params.get(xcode_target.id, EMPTY_STRING),
                )
                top_level_targets_args.add(
                    xcode_target.product.executable_name or EMPTY_STRING)
                top_level_targets_args.add(xcode_target.compile_target_ids)
                top_level_targets_args.add(unit_test_host)

    actions.write(target_arguments_file, targets_args)
    actions.write(top_level_target_attributes_file, top_level_targets_args)

    # FIXME: Add test case for this
    for id in uniq(unit_test_host_ids):
        unit_test_host_target = xcode_targets[id]
        if not unit_test_host_target:
            fail(
                """\
    Target ID for unit test host '{}' not found in xcode_targets
    """.format(unit_test_host),
            )
        unit_test_hosts_args.add(id)
        unit_test_hosts_args.add(unit_test_host_target.package_bin_dir)
        unit_test_hosts_args.add(unit_test_host_target.product.file_path)
        unit_test_hosts_args.add(
            unit_test_host_target.product.executable_name or
            unit_test_host_target.product.name,
        )

    actions.write(unit_test_host_attributes_file, unit_test_hosts_args)

    # colorize
    if colorize:
        args.add(_flags.colorize)

    message = "Generating {} PBXNativeTargets partials (shard {})".format(
        install_path,
        idx,
    )

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
            consolidation_map,
            target_arguments_file,
            top_level_target_attributes_file,
            unit_test_host_attributes_file,
        ] + build_settings_files,
        outputs = [
            pbxnativetargets,
            buildfile_subidentifiers,
        ],
        progress_message = message,
        mnemonic = "WritePBXNativeTargets",
        execution_requirements = {
            # Lots of files to read, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return (
        pbxnativetargets,
        buildfile_subidentifiers,
    )

# `project.pbxproj`

def _write_project_pbxproj(
        *,
        actions,
        files_and_groups,
        generator_name,
        pbxproj_prefix,
        pbxproject_targets,
        pbxproject_known_regions,
        pbxproject_target_attributes,
        pbxtargetdependencies,
        targets):
    """Creates a `project.pbxproj` `File`.

    Args:
        actions: `ctx.actions`.
        files_and_groups: The `files_and_groups` `File` returned from
            `pbxproj_partials.write_files_and_groups`.
        generator_name: The name of the `xcodeproj` generator target.
        pbxproj_prefix: The `File` returned from
            `pbxproj_partials.write_pbxproj_prefix`.
        pbxproject_known_regions: The `known_regions` `File` returned from
            `pbxproj_partials.write_known_regions`.
        pbxproject_target_attributes: The `pbxproject_target_attributes` `File` returned from
            `pbxproj_partials.write_pbxproject_targets`.
        pbxproject_targets: The `pbxproject_targets` `File` returned from
            `pbxproj_partials.write_pbxproject_targets`.
        pbxtargetdependencies: The `pbxtargetdependencies` `Files` returned from
            `pbxproj_partials.write_pbxproject_targets`.
        targets: The `targets` `list` of `Files` returned from
            `pbxproj_partials.write_targets`.

    Returns:
        A `project.pbxproj` `File`.
    """
    output = actions.declare_file("{}.project.pbxproj".format(generator_name))

    inputs = [
        pbxproj_prefix,
        pbxproject_target_attributes,
        pbxproject_known_regions,
        pbxproject_targets,
    ] + targets + [
        pbxtargetdependencies,
        files_and_groups,
    ]

    args = actions.args()
    args.use_param_file("%s")
    args.set_param_file_format("multiline")
    args.add_all(inputs)

    actions.run_shell(
        arguments = [args],
        inputs = inputs,
        outputs = [output],
        command = """\
cat "$@" > {output}
""".format(output = output.path),
        mnemonic = "WriteXcodeProjPBXProj",
        progress_message = "Generating %{output}",
        execution_requirements = {
            # Absolute paths
            "no-remote": "1",
            # Each file is directly referenced, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return output

def _write_xcfilelists(*, actions, files, file_paths, generator_name):
    external_args = actions.args()
    external_args.set_param_file_format("multiline")
    external_args.add_all(
        files,
        map_each = _filter_external_file,
    )
    external_args.add_all(
        file_paths,
        map_each = _filter_external_file_path,
    )

    external = actions.declare_file(
        "{}-xcfilelists/external.xcfilelist".format(generator_name),
    )
    actions.write(external, external_args)

    generated_args = actions.args()
    generated_args.set_param_file_format("multiline")
    generated_args.add_all(
        files,
        map_each = _filter_generated_file,
    )
    generated_args.add_all(
        file_paths,
        map_each = _filter_generated_file_path,
    )

    generated = actions.declare_file(
        "{}-xcfilelists/generated.xcfilelist".format(generator_name),
    )
    actions.write(generated, generated_args)

    return [external, generated]

pbxproj_partials = struct(
    write_files_and_groups = _pbxproj_partials.write_files_and_groups,
    write_target_build_settings = _write_target_build_settings,
    write_project_pbxproj = _write_project_pbxproj,
    write_pbxproj_prefix = _pbxproj_partials.write_pbxproj_prefix,
    write_pbxtargetdependencies = _pbxproj_partials.write_pbxtargetdependencies,
    write_schemes = _write_schemes,
    write_swift_debug_settings = _write_swift_debug_settings,
    write_targets = _write_targets,
    write_xcfilelists = _write_xcfilelists,
)

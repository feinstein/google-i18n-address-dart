#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// The main entry point for the update_json_files executable.
///
/// This script finds the project root and runs the update_json_files.dart script from the tool directory.
void main(List<String> arguments) {
  // Get the directory of this script
  final scriptDir = path.dirname(Platform.script.toFilePath());

  // Find the project root (assuming bin is directly under project root)
  final projectRoot = path.dirname(scriptDir);

  // Path to the tool script
  final toolScript = path.join(projectRoot, 'tool', 'update_json_files.dart');

  // Check if the tool script exists
  if (!File(toolScript).existsSync()) {
    stderr.writeln('Error: Tool script not found at $toolScript');
    exit(1);
  }

  // Construct the process arguments
  final processArgs = [
    toolScript,
    ...arguments,
  ];

  // Run the tool script
  final result = Process.runSync(
    Platform.executable, // dart executable
    processArgs,
    runInShell: true,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  // Output the result
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  // Exit with the same exit code
  exit(result.exitCode);
}

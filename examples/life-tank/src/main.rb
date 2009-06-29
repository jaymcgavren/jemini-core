require 'java'

$profiling = false #change this to true to start the profiler
if $profiling
  require 'profile'
  Java::java::lang::Runtime.runtime.add_shutdown_hook(Java::java::lang::Thread.new do
    Profiler__::print_profile(STDERR) if $profiling
  end)
end

$LOAD_PATH.clear
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'game_objects'))
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'managers'))
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'states'))
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../../../src')


# only when running in non-standalone
if File.exist? File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib'))
  jar_glob = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', '*.jar'))
  Dir.glob(jar_glob).each do |jar|
    $CLASSPATH << jar
  end
end

require 'gemini'

begin
  Gemini::Main.start_app("Life Tank", 800, 600, :MenuState, false)
#  Gemini::Main.start_app("Life Tank", 800, 600, :InputDiagnosticState, false)
rescue => e
  warn e
  warn e.backtrace
end
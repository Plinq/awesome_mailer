# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', all_after_pass: false, all_on_start: false, focus_on_failed: true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { "spec" }
  watch('spec/spec_helper.rb')  { "spec" }
end

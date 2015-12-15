Pod::Spec.new do |s|
  s.name         = "BugsnagKSCrash"
  s.version      = "0.0.8"
  s.summary      = "The Ultimate iOS Crash Reporter"
  s.homepage     = "https://github.com/bugsnag/BugsnagKSCrash"
  s.license     = { :type => 'KSCrash license agreement', :file => 'LICENSE' }
  s.author       = { "Karl Stenerud" => "kstenerud@gmail.com" }
  s.platform     = :ios, '5.0'
  s.source       = { :git => "https://github.com/bugsnag/BugsnagKSCrash.git", :tag=>s.version.to_s }
  s.frameworks = 'Foundation'
  s.libraries = 'c++', 'z'
  s.xcconfig = { 'GCC_ENABLE_CPP_EXCEPTIONS' => 'YES' }

  s.subspec 'no-arc' do |sp|
    sp.source_files = 'Source/KSCrash/Recording/**/BugsnagKSZombie.{h,m}'
    sp.requires_arc = false
  end

  s.subspec 'Recording' do |recording|
    recording.dependency 'KSCrash/no-arc'
    recording.source_files   = 'Source/KSCrash/Recording/**/*.{h,m,mm,c,cpp}',
                               'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilter.h'
    recording.exclude_files = 'Source/KSCrash/Recording/**/BugsnagKSZombie.{h,m}'
  end

  s.subspec 'Reporting' do |reporting|
    reporting.dependency 'KSCrash/Recording'

    reporting.subspec 'Filters' do |filters|
      filters.subspec 'Base' do |base|
        base.source_files = 'Source/KSCrash/Reporting/Filters/Tools/**/*.{h,m,mm,c,cpp}',
                            'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilter.h',
                            'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilter.m'
      end

      filters.subspec 'Alert' do |alert|
        alert.dependency 'KSCrash/Reporting/Filters/Base'
        alert.source_files = 'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterAlert.h',
                             'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterAlert.m'
      end

      filters.subspec 'AppleFmt' do |applefmt|
        applefmt.dependency 'KSCrash/Reporting/Filters/Base'
        applefmt.source_files = 'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterAppleFmt.h',
                             'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterAppleFmt.m'
      end

      filters.subspec 'Basic' do |basic|
        basic.dependency 'KSCrash/Reporting/Filters/Base'
        basic.source_files = 'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterBasic.h',
                             'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterBasic.m'
      end

      filters.subspec 'GZip' do |gzip|
        gzip.dependency 'KSCrash/Reporting/Filters/Base'
        gzip.source_files = 'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterGZip.h',
                            'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterGZip.m'
      end

      filters.subspec 'JSON' do |json|
        json.dependency 'KSCrash/Reporting/Filters/Base'
        json.source_files = 'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterJSON.h',
                            'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterJSON.m'
      end

      filters.subspec 'Sets' do |sets|
        sets.dependency 'KSCrash/Reporting/Filters/Base'
        sets.dependency 'KSCrash/Reporting/Filters/AppleFmt'
        sets.dependency 'KSCrash/Reporting/Filters/Basic'
        sets.dependency 'KSCrash/Reporting/Filters/GZip'
        sets.dependency 'KSCrash/Reporting/Filters/JSON'

        sets.source_files = 'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterSets.h',
                            'Source/KSCrash/Reporting/Filters/BugsnagKSCrashReportFilterSets.m'
      end

    end

    reporting.subspec 'Tools' do |tools|
      tools.frameworks = 'SystemConfiguration'
      tools.source_files = 'Source/KSCrash/Reporting/Tools/**/*.{h,m,mm,c,cpp}'

    end

    reporting.subspec 'Sinks' do |sinks|
      sinks.frameworks = 'MessageUI'
      sinks.dependency 'KSCrash/Reporting/Filters'
      sinks.dependency 'KSCrash/Reporting/Tools'
      sinks.source_files = 'Source/KSCrash/Reporting/Sinks/**/*.{h,m,mm,c,cpp}'
    end

  end

  s.subspec 'Installations' do |installations|
    installations.dependency 'KSCrash/Recording'
    installations.dependency 'KSCrash/Reporting'
    installations.source_files = 'Source/KSCrash/Installations/**/*.{h,m,mm,c,cpp}'
  end

end

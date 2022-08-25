#!/usr/bin/env ruby

require 'erb'
require 'json'

template_file = File.open('catalog-info-from-tas-plugin2.yaml.erb')
template_string = template_file.read

template = ERB.new template_string

apps_response = `cf curl /v3/apps?include=space.organization`
apps_response_data = JSON.parse(apps_response)

orgs = apps_response_data.dig('included', 'organizations').inject({}) { |acc, o| acc[o['guid']] = o; acc }
spaces = apps_response_data.dig('included', 'spaces').inject({}) { |acc, s| acc[s['guid']] = s; acc }

apps = apps_response_data.dig('resources').map do |app|
  space = spaces[app.dig('relationships', 'space', 'data', 'guid')]
  org = orgs[space.dig('relationships', 'organization', 'data', 'guid')]
  {
    name: app['name'],
    org: org['name'],
    space: space['name'],
    service_instances: [{name: 'hardcoded-si-name'}],
    system: app.dig('metadata', 'labels', 'system'),
    codebase: app.dig('metadata', 'labels', 'codebase'),
  }
end

foundation_response = `cf curl /v3/info`
foundation_response_data = JSON.parse(foundation_response)
 # set via https://bosh.io/jobs/cloud_controller_ng?source=github.com/cloudfoundry/capi-release&version=1.135.0#p%3dcc.info
foundation = {
  lifecycle: foundation_response_data.dig('custom', 'lifecycle')
}

puts template.result

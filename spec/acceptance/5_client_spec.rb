require 'spec_helper_acceptance'

describe 'keycloak_client define:', if: RSpec.configuration.keycloak_full do
  context 'creates client' do
    it 'runs successfully' do
      pp = <<-EOS
      include mysql::server
      class { 'keycloak':
        datasource_driver => 'mysql',
      }
      keycloak_realm { 'test': ensure => 'present' }
      keycloak_flow { 'foo on test': ensure => 'present' }
      keycloak_client { 'test.foo.bar':
        realm                          => 'test',
        root_url                       => 'https://test.foo.bar',
        redirect_uris                  => ['https://test.foo.bar/test1'],
        default_client_scopes          => ['address'],
        secret                         => 'foobar',
        login_theme                    => 'keycloak',
        authorization_services_enabled => false,
        service_accounts_enabled       => true,
        browser_flow                   => 'foo',
      }
      keycloak_client { 'test.foo.baz':
        realm                          => 'test',
        root_url                       => 'https://test.foo.bar',
        redirect_uris                  => ['https://test.foo.bar/test1'],
        default_client_scopes          => ['address'],
        secret                         => 'foobar',
        login_theme                    => 'keycloak',
        authorization_services_enabled => false,
        service_accounts_enabled       => true,
        browser_flow                   => 'foo',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'has created a client' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get clients/test.foo.bar -r test' do
        data = JSON.parse(stdout)
        expect(data['id']).to eq('test.foo.bar')
        expect(data['clientId']).to eq('test.foo.bar')
        expect(data['defaultClientScopes']).to eq(['address'])
        expect(data['rootUrl']).to eq('https://test.foo.bar')
        expect(data['redirectUris']).to eq(['https://test.foo.bar/test1'])
        expect(data['attributes']['login_theme']).to eq('keycloak')
        expect(data['authorizationServicesEnabled']).to eq(nil)
        expect(data['serviceAccountsEnabled']).to eq(true)
        expect(data['authenticationFlowBindingOverrides']['browser']).to eq('foo-test')
      end
    end

    it 'has created a client2' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get clients/test.foo.baz -r test' do
        data = JSON.parse(stdout)
        expect(data['authenticationFlowBindingOverrides']['browser']).to eq('foo-test')
      end
    end

    it 'has set the client secret' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get clients/test.foo.bar/client-secret -r test' do
        data = JSON.parse(stdout)
        expect(data['value']).to eq('foobar')
      end
    end
  end

  context 'updates client' do
    it 'runs successfully' do
      pp = <<-EOS
      include mysql::server
      class { 'keycloak':
        datasource_driver => 'mysql',
      }
      keycloak_realm { 'test': ensure => 'present' }
      keycloak_client { 'test.foo.bar':
        realm                          => 'test',
        root_url                       => 'https://test.foo.bar/test',
        redirect_uris                  => ['https://test.foo.bar/test2'],
        default_client_scopes          => ['profile', 'email'],
        secret                         => 'foobar',
        authorization_services_enabled => true,
        service_accounts_enabled       => true,
      }
      keycloak_client { 'test.foo.baz':
        realm                          => 'test',
        root_url                       => 'https://test.foo.bar',
        redirect_uris                  => ['https://test.foo.bar/test1'],
        default_client_scopes          => ['address'],
        secret                         => 'foobar',
        login_theme                    => 'keycloak',
        authorization_services_enabled => false,
        service_accounts_enabled       => true,
        browser_flow                   => 'browser',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'has updated a client' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get clients/test.foo.bar -r test' do
        data = JSON.parse(stdout)
        expect(data['id']).to eq('test.foo.bar')
        expect(data['clientId']).to eq('test.foo.bar')
        expect(data['defaultClientScopes']).to eq(['profile', 'email'])
        expect(data['rootUrl']).to eq('https://test.foo.bar/test')
        expect(data['redirectUris']).to eq(['https://test.foo.bar/test2'])
        expect(data['attributes']['login_theme']).to be_nil
        expect(data['authorizationServicesEnabled']).to eq(true)
        expect(data['serviceAccountsEnabled']).to eq(true)
        expect(data['authenticationFlowBindingOverrides']).to eq({})
      end
    end

    it 'has updated a client flow' do
      browser_id = nil
      on hosts, "/opt/keycloak/bin/kcadm-wrapper.sh get authentication/flows -r test --fields 'id,alias'" do
        data = JSON.parse(stdout)
        data.each do |d|
          if d['alias'] == 'browser'
            browser_id = d['id']
            break
          end
        end
      end
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get clients/test.foo.baz -r test' do
        data = JSON.parse(stdout)
        expect(data['authenticationFlowBindingOverrides']['browser']).to eq(browser_id)
      end
    end

    it 'has set the same client secret' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get clients/test.foo.bar/client-secret -r test' do
        data = JSON.parse(stdout)
        expect(data['value']).to eq('foobar')
      end
    end
  end
end

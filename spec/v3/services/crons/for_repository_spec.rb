describe Travis::API::V3::Services::Crons::ForRepository, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo).first }
  let(:cron)  { Travis::API::V3::Models::Cron.create(branch: branch, interval:'daily') }
  let(:parsed_body) { JSON.load(body) }

  before do
    Travis::Features.activate_owner(:cron, repo.owner)
  end

  describe "fetching all crons by repo id with feature disabled" do
    before     { Travis::Features.deactivate_owner(:cron, repo.owner)   }
    before     { get("/v3/repo/#{repo.id}/crons")   }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "insufficient_access",
      "error_message" => "forbidden"
    }}
  end

  describe "fetching all crons by repo id" do
    before     { cron }
    before     { get("/v3/repo/#{repo.id}/crons")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"              => "crons",
        "@href"             => "/v3/repo/#{repo.id}/crons",
        "@representation"   => "standard",
        "@pagination"       => {
          "limit"           => 25,
          "offset"          => 0,
          "count"           => 1,
          "is_first"        => true,
          "is_last"         => true,
          "next"            => nil,
          "prev"            => nil,
          "first"           => {
                "@href"     => "/v3/repo/#{repo.id}/crons",
                "offset"    => 0,
                "limit"     => 25},
          "last"      => {
                "@href"     => "/v3/repo/#{repo.id}/crons",
                "offset"    => 0,
                "limit"     => 25 }},
          "crons"           => [
            {
                "@type"               => "cron",
                "@href"               => "/v3/cron/#{cron.id}",
                "@representation"     => "standard",
                "@permissions"        => {
                    "read"            => true,
                    "delete"          => false,
                    "start"           => true },
                "id"                  => cron.id,
                "repository"          => {
                    "@type"           => "repository",
                    "@href"           => "/v3/repo/#{repo.id}",
                    "@representation" => "minimal",
                    "id"              => repo.id,
                    "name"            => "minimal",
                    "slug"            => "svenfuchs/minimal" },
                "branch"              => {
                    "@type"           => "branch",
                    "@href"           => "/v3/repo/#{repo.id}/branch/#{branch.name}",
                    "@representation" => "minimal",
                    "name"            => "#{branch.name}" },
                "interval"            => "daily",
                "disable_by_build"    => true,
                "next_enqueuing"      => cron.next_enqueuing.strftime('%Y-%m-%dT%H:%M:%SZ'),
                "created_at"          => cron.created_at.strftime('%Y-%m-%dT%H:%M:%SZ')
            }
          ]
    }}
  end

  describe "fetching crons on a non-existing repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal1/crons")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "fetching crons from private repo, not authenticated" do
    before  { repo.update_attribute(:private, true)  }
    before  { get("/v3/repo/#{repo.id}/crons")             }
    after   { repo.update_attribute(:private, false) }
    example { expect(last_response).to be_not_found  }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

end

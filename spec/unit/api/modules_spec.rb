require 'spec_helper'
require 'r10k/api/modules'

RSpec.describe R10K::API::Modules do
  include_context "R10K::API"

  # Note: This file only contains tests for the private class methods
  # contained in this module. Since the various R10K::API namespaces
  # are not designed to be used independently, the public class methods
  # are tested in the unit tests for the collective R10K::API namepsace.

  describe ".resolve_git_module" do
    let(:git_mod) { unresolved_git_modules.sample }

    it "requires a cachedir option" do
      expect { subject.send(:resolve_git_module, git_mod) }.to raise_error(RuntimeError, /value.*required.*cachedir/i)
    end

    it "uses git.rev_parse to resolve version" do
      expect(R10K::API::Git).to receive(:rev_parse).with(git_mod[:version], anything).and_return("abc123")

      expect(subject.send(:resolve_git_module, git_mod, {cachedir: cachedir})).to include(resolved_version: "abc123")
    end

    it "raises appropriatly on failure" do
      expect(R10K::API::Git).to receive(:rev_parse).and_raise(R10K::Git::GitError.new('arbitrary failure'))

      expect { subject.send(:resolve_git_module, git_mod, {cachedir: cachedir}) }.to raise_error(R10K::API::Errors::UnresolvableError, /unable.*resolve.*valid.*git.*commit/i)
    end

    it "returns complete mod hash with resolved_version key added" do
      allow(R10K::API::Git).to receive(:rev_parse).and_return("abc123")

      expect(subject.send(:resolve_git_module, git_mod, {cachedir: cachedir})).to eq(git_mod.merge(resolved_version: "abc123"))
    end
  end

  describe ".resolve_forge_module" do
    let(:mock_releases) do
      [
        double(:release, version: "3.0.0-pre"),
        double(:release, version: "2.0.0"),
        double(:release, version: "1.4.2"),
        double(:release, version: "1.0.0"),
        double(:release, version: "0.2.9"),
      ]
    end

    let(:mock_forge_module) { instance_double(PuppetForge::V3::Module, releases: mock_releases) }

    context "when module is 'unpinned'" do
      context "when module is not already deployed" do
        let(:forge_mod) { unresolved_forge_modules.find { |m| m[:version] == 'unpinned' && !m[:deployed_version] } }

        it "should resolve as :latest" do
          allow(PuppetForge::V3::Module).to receive(:find_stateless).with(forge_mod[:source], {}).and_return(mock_forge_module)

          expect(subject.send(:resolve_forge_module, forge_mod)).to eq(forge_mod.merge(resolved_version: "2.0.0"))
        end
      end

      context "when module is already deployed" do
        let(:forge_mod) { unresolved_forge_modules.find { |m| m[:version] == 'unpinned' && m[:deployed_version] } }

        it "should resolve to deployed version" do
          allow(PuppetForge::V3::Module).to receive(:find_stateless).with(forge_mod[:source]).and_return(mock_forge_module)

          expect(subject.send(:resolve_forge_module, forge_mod)).to eq(forge_mod.merge(resolved_version: forge_mod[:deployed_version]))
        end
      end
    end

    context "when module is pinned to 'latest'" do
      let(:forge_mod) { unresolved_forge_modules.find { |m| m[:version] == 'latest' } }

      it "should resolve as :latest" do
        allow(PuppetForge::V3::Module).to receive(:find_stateless).with(forge_mod[:source], {}).and_return(mock_forge_module)

        expect(subject.send(:resolve_forge_module, forge_mod)).to eq(forge_mod.merge(resolved_version: "2.0.0"))
      end
    end

    context "when module is pinned to N.x-style range" do
      let(:forge_mod) { unresolved_forge_modules.find { |m| m[:version] == "1.x" } }

      it "should resolve as latest in range" do
        allow(PuppetForge::V3::Module).to receive(:find_stateless).with(forge_mod[:source], {}).and_return(mock_forge_module)

        expect(subject.send(:resolve_forge_module, forge_mod)).to eq(forge_mod.merge(resolved_version: "1.4.2"))
      end
    end

    context "when module is pinned to >=<-style range" do
      let(:forge_mod) { unresolved_forge_modules.find { |m| m[:version] == ">=1.4.0 <1.5.0" } }

      it "should resolve as latest in range" do
        allow(PuppetForge::V3::Module).to receive(:find_stateless).with(forge_mod[:source], {}).and_return(mock_forge_module)

        expect(subject.send(:resolve_forge_module, forge_mod)).to eq(forge_mod.merge(resolved_version: "1.4.2"))
      end
    end

    context "when module is pinned to version" do
      let(:forge_mod) { unresolved_forge_modules.find { |m| m[:version] == "1.0.0" } }

      it "should resolve to exact version" do
        allow(PuppetForge::V3::Module).to receive(:find_stateless).with(forge_mod[:source], {}).and_return(mock_forge_module)

        expect(subject.send(:resolve_forge_module, forge_mod)).to eq(forge_mod.merge(resolved_version: "1.0.0"))
      end
    end
  end
end

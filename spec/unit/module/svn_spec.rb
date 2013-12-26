require 'spec_helper'

require 'r10k/module/svn'

describe R10K::Module::SVN do

  describe "determining it implements a Puppetfile mod" do
    it "implements mods with the :svn hash key"
  end

  describe "instantiating based on Puppetfile configuration" do
    it "can specify a revision"
    it "can specify a path within the SVN repo"
  end

  describe "determining the status" do
    it "is :absent if the module directory is absent"
    it "is :mismatched if the directory is present but not an SVN repo"
    it "is :mismatched if the directory URL doesn't match the expected repo"

    it "is some state when the wrong working copy path is checked out"

    it "is :outdated when the expected rev doesn't match the actual rev"

    it "is :insync if all other conditions are satisfied"
  end

  describe "synchronizing" do
    describe "and the state is :absent" do
      it "installs the SVN module"
      it "performs an SVN checkout of the repository"
    end

    describe "and the state is :mismatched" do
      it "reinstalls the module"
      it "removes the existing directory"
      it "performs an SVN checkout of the repository"
    end

    describe "and the state is :outdated" do
      it "upgrades the repository"
      it "performs an svn update on the repository"
    end

    describe "and the state is :insync" do
      it "doesn't change anything"
    end
  end
end

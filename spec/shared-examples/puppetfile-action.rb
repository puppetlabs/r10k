require 'spec_helper'

shared_examples_for "a puppetfile action" do
  describe "initializing" do
    it "accepts the :root option" do
      described_class.new({root: "/some/nonexistent/path"}, [])
    end

    it "accepts the :puppetfile option" do
      described_class.new({puppetfile: "/some/nonexistent/path/Puppetfile"}, [])
    end

    it "accepts the :moduledir option" do
      described_class.new({moduledir: "/some/nonexistent/path/modules"}, [])
    end

  end
end

shared_examples_for "a puppetfile install action" do
  describe "initializing" do
    it "accepts the :root option" do
      described_class.new({root: "/some/nonexistent/path"}, [])
    end

    it "accepts the :puppetfile option" do
      described_class.new({puppetfile: "/some/nonexistent/path/Puppetfile"}, [])
    end

    it "accepts the :moduledir option" do
      described_class.new({moduledir: "/some/nonexistent/path/modules"}, [])
    end

    it "accepts the :force option" do
      described_class.new({force: true}, [])
    end

  end
end

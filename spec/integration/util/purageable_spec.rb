require 'spec_helper'
require 'r10k/util/purgeable'
require 'r10k/util/cleaner'

require 'tmpdir'

RSpec.describe R10K::Util::Purgeable do
  it 'purges only unmanaged files' do
    Dir.mktmpdir do |envdir|
      managed_directory = "#{envdir}/managed_one"
      desired_contents = [
        "#{managed_directory}/expected_1",
        "#{managed_directory}/managed_subdir_1",
        "#{managed_directory}/managed_symlink_dir",
        "#{managed_directory}/managed_subdir_1/subdir_expected_1",
        "#{managed_directory}/managed_subdir_1/managed_symlink_file",
      ]

      FileUtils.cp_r('spec/fixtures/unit/util/purgeable/managed_one/',
                     managed_directory)

      cleaner = R10K::Util::Cleaner.new([managed_directory], desired_contents)

      cleaner.purge!({ recurse: true, whitelist: ["**/subdir_allowlisted_2"] })

      # Files present after purge
      expect(File.exist?("#{managed_directory}/expected_1")).to be true
      expect(File.exist?("#{managed_directory}/managed_subdir_1")).to be true
      expect(File.exist?("#{managed_directory}/managed_symlink_dir")).to be true
      expect(File.exist?("#{managed_directory}/managed_subdir_1/subdir_expected_1")).to be true
      expect(File.exist?("#{managed_directory}/managed_subdir_1/managed_symlink_file")).to be true
      expect(File.exist?("#{managed_directory}/managed_subdir_1/subdir_allowlisted_2")).to be true

      # Purged files
      expect(File.exist?("#{managed_directory}/unmanaged_1")).to be false
      expect(File.exist?("#{managed_directory}/managed_subdir_1/unmanaged_symlink_dir")).to be false
      expect(File.exist?("#{managed_directory}/unmanaged_symlink_file")).to be false
      expect(File.exist?("#{managed_directory}/managed_subdir_1/subdir_unmanaged_1")).to be false
    end
  end
end

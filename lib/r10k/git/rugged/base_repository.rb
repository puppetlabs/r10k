require 'r10k/git/rugged'

class R10K::Git::Rugged::BaseRepository

  def resolve(pattern)
    object = with_repo { |repo| repo.rev_parse(pattern) }
    case object
    when NilClass
      nil
    when ::Rugged::Tag, ::Rugged::Tag::Annotation
      object.target.oid
    else
      object.oid
    end
  rescue ::Rugged::ReferenceError
    nil
  end

  def branches
    with_repo { |repo| repo.branches.each_name(:local).to_a }
  end

  def tags
    with_repo { |repo| repo.tags.each_name.to_a }
  end

  # @return [Symbol] The type of the given ref, one of :branch, :tag, :commit, or :unknown
  def ref_type(pattern)
    if branches.include? pattern
      :branch
    elsif tags.include? pattern
      :tag
    elsif resolve(pattern)
      :commit
    else
      :unknown
    end
  end

  private

  def with_repo
    yield @rugged_repo if @rugged_repo
  ensure
    @rugged_repo.close if @rugged_repo
  end
end

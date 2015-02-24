require 'r10k/git/rugged'

class R10K::Git::Rugged::BaseRepository

  def resolve(pattern)
    object = @rugged_repo.rev_parse(pattern)
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
    @rugged_repo.branches.each_name(:local).to_a
  end

  def tags
    @rugged_repo.tags.each_name.to_a
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
end

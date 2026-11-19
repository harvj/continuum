module ContinuumVersion
  COMPONENT = /(?:0|[1-9][0-9]*)/
  FORMAT = /\A#{COMPONENT}\.#{COMPONENT}\.#{COMPONENT}\n?\z/

  def self.parse(contents)
    raise ArgumentError, "VERSION must contain MAJOR.MINOR.PATCH" unless FORMAT.match?(contents)

    contents.chomp
  end

  def self.read(root = File.expand_path("..", __dir__))
    parse(File.binread(File.join(root, "VERSION")))
  end
end

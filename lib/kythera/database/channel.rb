#
# kythera: services for IRC networks
# lib/kythera/database/user.rb: registered users
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

module Database

    # A registered user has these attributes:
    #
    # name
    # register_date
    #
    class Channel < Sequel::Model
        one_to_many :channel_flags
        one_to_many :channel_user_flags

        def initialize(*args)
            @user_lookup  = {}
            @flag_lookup = {}
            super(*args)
        end

        # Registers a new user
        #
        # @param [String] name the channel name
        # @return [Database::Channel] channel object
        #
        def self.register(name)
            channel = Channel.new

            channel.name = name
            channel.register_date = Time.now
            channel.save

            channel
        end

        # Returns channel flags as Symbols instead of objects
        #
        # @return [Array] Symbols for all flags
        #
        def flags
            # iterate each ChannelFlag object and just cache the "flag" member
            # as a Symbol, cause that's what we'll need most frequently
            @flags ||= channel_flags.collect { |cf| cf.flag.to_sym }
        end

        # Returns channel user flags as Symbols instead of objects
        #
        # @param [User,Integer] user a user object or id to find the flags
        #
        def user_flags(user)
            id = user.to_i

            @user_lookup[id] ||= channel_user_flags.collect do |cuf|
                cuf.user.id == id ? cuf.flag.to_sym : nil
            end.compact
        end

        # Returns the users that have access via the given flag
        #
        # @param [Symbol,String] flag a flag to examine
        # @return [Array<User>] user objects
        #
        def flag_users(flag)
            flag = flag.to_sym

            @flag_lookup[flag] ||= channel_user_flags.collect do |cuf|
                cuf.flag.to_sym == flag ? cuf.user.id : nil
            end.compact
        end

        # Adds flags to a user for channel access
        #
        # @param [User,Integer] user the user object or ID being granted access
        # @param [Symbol,String] flags_to_add a flag or flags to add
        #
        def add_user_access(user, *flags_to_add)
            # normalize arguments into a form we'll recognize
            flags_to_add.collect! { |flag| flag.to_sym }
            id = user.to_i

            # backup our arguments in case we need to restore to them later
            flags = user_flags(id)
            flags_backup = flags.dup
            flag_lookup_backup = {}
            flags_to_add.each do |flag|
                flag_lookup_backup[flag] = flag_users(flag).dup
            end

            begin
                $db.transaction do
                    flags_to_add.each do |flag|
                        # don't bother adding a flag we've already got
                        next if flags.include?(flag.to_sym)

                        # otherwise, make a new ChannelFlag object and set it up
                        channel_user_flag = ChannelUserFlag.new
                        channel_user_flag.channel = self
                        channel_user_flag.user_id = id
                        channel_user_flag.flag    = flag.to_s

                        # add the flags to our cache and the DB
                        flags << flag
                        add_channel_user_flag(channel_user_flag)
                        flag_lookup = flag_users(flag)
                        flag_lookup << id unless flag_lookup.include?(id)
                    end
                end
            rescue Exception => e
                # rollback changes to our cache if we couldn't save
                @user_lookup[id] = flags_backup
                flag_lookup_backup.each do |flag, users|
                    @flag_lookup[flag] = users
                end

                # reraise cause we don't know for sure how to proceed from here
                raise e
            end
        end

        # Removes flags from a user for channel access
        #
        # @param [User,Integer] user the user object or ID being revoked access
        # @param [Symbol,String] flags_to_rem a flag or flags to remove
        #
        def remove_user_access(user, *flags_to_rem)
            # normalize arguments into a form we'll recognize
            flags_to_rem.collect! { |flag| flag.to_sym }
            id = user.to_i

            # backup our arguments in case we need to restore to them later
            flags = user_flags(id)
            flags_backup = flags.dup
            flag_lookup_backup = {}
            flags_to_rem.each do |flag|
                next unless @flag_lookup[flag]
                flag_lookup_backup[flag] = @flag_lookup[flag].dup
            end

            # time to actually do the work to remove flags
            begin
                # transaction safety!
                $db.transaction do
                    flags_to_rem.each do |flag|
                        # find if this user even has a given flag
                        ftr = channel_user_flags.find do |f|
                            f.flag.to_sym == flag and f.user.id == id
                        end
                        next unless ftr

                        # delete the flags from the database and our user cache
                        flags.delete_if { |f| f == flag }
                        ftr.delete

                        # delete the user from the reverse flag lookup if
                        # necessary
                        if @flag_lookup[flag]
                            @flag_lookup.delete_if { |uid| uid == id }
                        end
                    end
                end
            rescue Exception => e
                # rollback changes to our cache if we couldn't save
                @user_lookup[id] = flags_backup
                flag_lookup_backup.each do |flag, users|
                    @flag_lookup[flag] = users
                end

                # reraise cause we don't know for sure how to proceed from here
                raise e
            end
        end

        # Adds flags to a Channel
        #
        # @param [Symbol,String] flags_to_add a flag or flags to add
        #
        def add_flags(*flags_to_add)
            # backup our cache because we're going to be editing it directly,
            # and we want to ensure we can rollback if problems arise
            cf = flags.dup

            begin
                # transaction safety!
                $db.transaction do
                    flags_to_add.each do |flag|
                        # don't bother adding a flag we've already got
                        next if flags.include?(flag.to_sym)

                        # otherwise, make a new ChannelFlag object and set it up
                        channel_flag = ChannelFlag.new
                        channel_flag.flag = flag.to_s

                        # add the flags to our cache and the DB
                        flags << flag.to_sym
                        add_channel_flag(channel_flag)
                    end
                end
            rescue Exception => e
                # rollback changes to our cache if we couldn't save, and then
                # reraise cause we don't know for sure how to proceed from here
                @flags = cf
                raise e
            end
        end

        # Removes flags from a Channel
        #
        # @param [Symbol,String] flags_to_rem a flag or flags to remove
        #
        def remove_flags(*flags_to_rem)
            # backup our cache because we're going to be editing it directly,
            # and we want to ensure we can rollback if problems arise
            cf = flags.dup

            begin
                # transaction safety!
                $db.transaction do
                    flags_to_rem.each do |flag|
                        # find the flag in the channel_flags so we can get the
                        # ChannelFlag object proper, not just a Symbol
                        ftr = channel_flags.find { |f| f.flag == flag.to_s }
                        next unless ftr

                        # delete the element in our cached array as well as in
                        # the database
                        flags.delete_if { |f| f == flag.to_sym }
                        ftr.delete
                    end
                end
            rescue Exception => e
                # rollback changes to our cache if we couldn't save, and then
                # reraise cause we don't know for sure how to proceed from here
                @flags = cf
                raise e
            end
        end

        # Converts object to its database ID
        #
        # @return [Integer] database ID
        #
        def to_i
            id
        end

        # Determines if a user has an access level
        #
        # @param [User,Integer] user the user object or ID to check
        # @param [Symbol,String] flag the flag to check
        # @return [Boolean] if the user has access
        #
        def user_has_access?(user, flag)
            user_flags(user).include?(flag.to_sym)
        end
    end

    class ChannelFlag < Sequel::Model
        many_to_one :channel
        include GenericFlag
    end
end

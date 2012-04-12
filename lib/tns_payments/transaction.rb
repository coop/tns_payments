module TNSPayments
  class Transaction < SimpleDelegator
    attr_writer :minimum_order_id

    def initialize transaction
      @transaction = transaction
      super
    end

    # Public: TNS require a minimum order_id of 10000000000 for what I can only
    #         assume is legacy requirements.
    #
    # Returns a minimum order_id.
    def minimum_order_id
      @minimum_order_id ||= 10000000000
    end

    # Public: TNS require an order_id to be sent with each transaction.
    #
    # Returns the order_id.
    def order_id
      minimum_order_id + @transaction.order_id.to_i
    end
  end
end

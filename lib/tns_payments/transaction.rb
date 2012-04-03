module TNSPayments
  class Transaction < SimpleDelegator
    attr_writer :minimum_order_id

    def initialize transaction
      @transaction = transaction
      super
    end

    def minimum_order_id
      @minimum_order_id ||= 10000000000
    end

    def order_id
      minimum_order_id + @transaction.order_id.to_i
    end
  end
end

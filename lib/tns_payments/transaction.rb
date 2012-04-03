module TNSPayments
  class Transaction < SimpleDelegator
    def initialize transaction
      @transaction = transaction
      super
    end

    def order_id
      10000000000 + @transaction.order_id.to_i
    end
  end
end

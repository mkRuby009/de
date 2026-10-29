select count(*) as total_payment_tx, sum(amount) as total_dollar_bill
from stg_payments

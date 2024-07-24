import math
q96 = 2**96
def price_to_sqrtp(p):
    return int(math.sqrt(p) * q96)

sqrtp_low = price_to_sqrtp(4545)
sqrtp_cur = price_to_sqrtp(5000)
sqrtp_upp = price_to_sqrtp(5500)



def liquidity0(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return (amount * (pa * pb) / q96) / (pb - pa)

def liquidity1(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return amount * q96 / (pb - pa)

eth = 10**18
amount_eth = 1 * eth
amount_usdc = 5000 * eth

liq0 = liquidity0(amount_eth, sqrtp_cur, sqrtp_upp)
liq1 = liquidity1(amount_usdc, sqrtp_cur, sqrtp_low)
liq = int(min(liq0, liq1))
print(liq0,liq1,liq)



# import math

# def price_to_tick(p):
#     return math.log(p, 1.0001)
    
    

# print(price_to_tick(5000))
# print((1.0000499987500624960940234169938**85176)**2)



# sqrtp_low = price_to_sqrtp(7)
# sqrtp_cur = price_to_sqrtp(9)
# sqrtp_upp = price_to_sqrtp(11.57142857142857)

# sqrtp_low = price_to_sqrtp(4545)
# sqrtp_cur = price_to_sqrtp(5000)
# sqrtp_upp = price_to_sqrtp(5500.5500550055)
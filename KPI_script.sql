With a as
(
select f.Stock as [Stock], Year(f.[Year]) as [Year], round(f.Value,2) as Loi_nhuan_sau_thue
from fact_income_statement as f
left join dim_stock ds 
on f.Stock = ds.Stock
where ds.Stock in ('BFC', 'BSR', 'DCM', 'DPM', 'DPR', 'GMD', 'HAH', 'HPG', 'IMP', 'NKG', 'PVD', 'PVT') and Year(f.[Year]) = '2024' and f.Id in ('20')
),
b as
(
select Round(SUM(table1.[Value]),2) as Von_chu_so_huu, table1.Stock as Ma_ck, table1.[Year] as Year1 from 
(
select f1.[Value], f1.[Stock], Year(f1.[Year]) as [Year]
from fact_balance_sheet f1
left join dim_balance_sheet d1
on f1.Lv4_ID = d1.Lv4_ID
where f1.Stock in ('BFC', 'BSR', 'DCM', 'DPM', 'DPR', 'GMD', 'HAH', 'HPG', 'IMP', 'NKG', 'PVD', 'PVT') and d1.[Lv2_ID] = '400'
) table1
group by table1.Stock, table1.[Year]
),
c as
(
Select a.* , b.Von_chu_so_huu, cast(round((a.[Loi_nhuan_sau_thue]/b.Von_chu_so_huu),4) * 100 as varchar) + ' %' as ROE
from a
left join b 
on a.[Stock] = b.[Ma_ck] and a.[Year] = b.[Year1]
),
g as
(
select d.*, e.Loi_nhuan_gop, e.Loi_nhuan_hdkd from 
( 
select c.[Year], c.[Stock], f3.[Value2] as Doanh_thu_thuan, c.Loi_nhuan_sau_thue, c.Von_chu_so_huu, c.ROE,
Cast(Round((c.Loi_nhuan_sau_thue/f3.Value2)*100,2) as varchar) + ' %' as Net_margin
from c
left join (select Round(f2.[Value],2) as Value2, Year(f2.[Year]) as Year2, f2.Stock as Stock2 from fact_income_statement as f2 where f2.Id = '2') f3
on c.[Year] = f3.[Year2] and c.[Stock] = f3.Stock2
) d
left join
(
SELECT r2.[Lãi/(lỗ) từ hoạt động kinh doanh] as Loi_nhuan_hdkd, r2.[Lợi nhuận gộp về bán hàng và cung cấp dịch vụ] as Loi_nhuan_gop, r2.[Stock]
FROM (
  SELECT [Item], [Stock], [Value]
  FROM fact_income_statement Where Year([Year]) = '2024'
) r1
PIVOT (SUM([Value])
  FOR [Item]
  IN (
    [Lãi/(lỗ) từ hoạt động kinh doanh], [Lợi nhuận gộp về bán hàng và cung cấp dịch vụ]
  )
) AS r2
) e
on d.Stock = e.Stock ),
h as
(
SELECT r2.[Year], r2.[Stock], 
Round(r2.[Cac_khoan_phai_thu],2) as Cac_khoan_phai_thu, 
Round(r2.[Hang_ton_kho_rong],2) as Hang_ton_kho_rong
FROM (
			select Year(step1.[Year]) as [Year],  step1.[Stock], sum(step1.[Value]) as [Value], step1.danh_dau
			from
			(
			select *, 
				case 
					when Lv4_ID in ('139', '137', '136', '135', '134', '133', '132', '13101') then 'Cac_khoan_phai_thu'
					when Lv4_ID in ('149', '141') then 'Hang_ton_kho_rong'
				end as danh_dau
			from fact_balance_sheet 
			where Lv4_ID in ('139', '137', '136', '135', '134', '133', '132', '13101', '149', '141')
			) step1
			group by step1.[Stock], step1.danh_dau, step1.[Year]
) r1
PIVOT (SUM([Value])
  FOR [danh_dau]
  IN (
    [Cac_khoan_phai_thu], [Hang_ton_kho_rong]
  )
) AS r2
)
select g.[Year], g.[Stock], s.Phan_loai_1 as [Nhóm], s.Phan_loai_2 as [Loại hình],
g.Doanh_thu_thuan as [Doanh thu thuần], Round(g.Loi_nhuan_gop,2) as [Lợi nhuận gộp], Round((g.Doanh_thu_thuan - g.Loi_nhuan_gop),2) as [Giá vốn hàng bán],
Round(g.Loi_nhuan_hdkd,2) as [Lợi nhuận HĐKD],
h.Cac_khoan_phai_thu as [Các khoản phải thu], h.Hang_ton_kho_rong as [Hàng tồn kho], g.Von_chu_so_huu as [Vốn chủ sở hữu], 
g.Net_margin as [Biên lợi nhuận thuần], 
Cast(Round((g.Loi_nhuan_gop/g.Doanh_thu_thuan) * 100,2) as varchar) + ' %' as [Biên lợi nhuận gộp],
Cast(Round((g.Loi_nhuan_hdkd/g.Doanh_thu_thuan) * 100, 2) as varchar) + ' %' as [Biên lợi nhuận HĐKD],
Cast(Round((h.Cac_khoan_phai_thu/g.Doanh_thu_thuan * 360),0) as varchar) + ' days' as [Số ngày phải thu],
Cast(Round((h.Hang_ton_kho_rong/(g.Doanh_thu_thuan - g.Loi_nhuan_gop) * 365),0) as varchar) + ' days' as [Số ngày tồn kho],
g.[ROE]
from g
left join h 
on h.[Year] = g.[Year] and h.Stock = g.Stock
left join dim_stock s 
on g.Stock = s.Stock








'use client'

import React from 'react'
import dynamic from 'next/dynamic'
import Card from '@mui/material/Card'
import { useTheme } from '@mui/material/styles'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'

const Chart = dynamic(() => import('react-apexcharts'), { ssr: false })

const PunctualityDonut = () => {
  const theme = useTheme()

  const options = {
    chart: { sparkline: { enabled: true } },
    colors: [theme.palette.success.main, theme.palette.warning.main, theme.palette.error.main],
    labels: ['Tepat Waktu', 'Terlambat', 'Alpa'],
    stroke: { width: 0 },
    legend: { show: false },
    plotOptions: {
      pie: {
        donut: {
          labels: {
            show: true,
            total: {
              show: true,
              label: 'Kehadiran',
              formatter: (val: string) => '92%'
            }
          }
        }
      }
    }
  }

  const series = [85, 10, 5]

  return (
    <Card sx={{ height: '100%' }}>
      <CardHeader 
        title='Persentase Ketepatan Waktu' 
        titleTypographyProps={{ variant: 'h6' }} 
        subheader='Bulan Ini'
      />
      <CardContent>
        <Chart type='donut' height={220} options={options as any} series={series} />
        <div className='mt-8 space-y-2'>
          <div className='flex justify-between items-center'>
            <Typography variant='body2'>Hadir Tepat Waktu</Typography>
            <Typography variant='body2' fontWeight='600'>85%</Typography>
          </div>
          <div className='flex justify-between items-center'>
            <Typography variant='body2'>Terlambat</Typography>
            <Typography variant='body2' fontWeight='600'>10%</Typography>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

export default PunctualityDonut

// src/app/(dashboard)/account-settings/page.tsx
'use client'

import type { ReactElement } from 'react'
import dynamic from 'next/dynamic'
import AccountSettings from '@views/account-settings'

const AccountTab = dynamic(() => import('@views/account-settings/account'))
const SecurityTab = dynamic(() => import('@views/account-settings/security'))
const CompanyTab = dynamic(() => import('@views/account-settings/company'))

const tabContentList = (): { [key: string]: ReactElement } => ({
  account: <AccountTab />,
  security: <SecurityTab />,
  company: <CompanyTab />
})

const AccountSettingsPage = () => {
  return <AccountSettings tabContentList={tabContentList()} />
}

export default AccountSettingsPage

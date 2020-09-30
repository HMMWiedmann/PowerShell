Setup-DSCWebPullServer -CertificateSubject CN=VCCDSC-01.MAIL.CLUSTER-CENTER.DE `
                       -FirewallPort 4711 `
                       -SQLProvider $true `
                       -SQLConnectionString 'Provider=SQLNCLI11;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=master;Data Source=VCCDSC-01\DSCPULLSERVER;Database=DSC'
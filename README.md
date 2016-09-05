This is a PowerShell module that allows you to convert between PowerShell and YAML objects.
You can do this 

    import-module psyaml
        $yamlString =@"
        invoice: !!str 34843
        date   : 2001-01-23
        approved: yes
        bill-to: 
            given  : Chris
            family : Dumars
            address:
                lines: |
                    458 Walkman Dr.
                    Suite #292
                city    : Royal Oak
                state   : MI
                postal  : 48046
        ship-to: id001
        product:
            - sku         : BL394D
              quantity    : 4
              description : Basketball
              price       : 450.00
            - sku         : BL4438H
              quantity    : 1
              description : Super Hoop
              price       : 2392.00
        tax  : 251.42
        total: 4443.52
        comments: >
            Late afternoon is best.
            Backup contact is Nancy
            Billsmer @ 338-4338.

    "@
    $YamlObject=ConvertFrom-YAML $yamlString
    ConvertTo-YAML $YamlObject
    
For all the background and details see the documentation

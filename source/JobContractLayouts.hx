package;

class JobContractLayouts
{
	public static function defaultDeskVariants():Array<JobContractVariant>
	{
		return [Kethran, Ostmark];
	}

	public static function get(variant:JobContractVariant):JobContractLayout
	{
		return switch (variant)
		{
			case Kethran: kethranNorthpoint();
			case Ostmark: ostmarkLoosyTale();
		}
	}

	public static function kethranNorthpoint():JobContractLayout
	{
		return {
			documentPath: "static/kethran_job_contract_with_name_1.png",
			nameScan: {
				x: 140,
				y: 1400,
				w: 270,
				h: 32,
				pad: 12.0
			},
			salaryScan: {
				x: 146,
				y: 1149,
				w: 207,
				h: 33
			}
		};
	}

	public static function ostmarkLoosyTale():JobContractLayout
	{
		return {
			documentPath: "static/ostmark_job_contract_with_name_1.png",
			nameScan: {
				x: 258,
				y: 415,
				w: 531,
				h: 45,
				pad: 8.0
			},
			salaryScan: {
				x: 91,
				y: 683,
				w: 359,
				h: 78
			}
		};
	}
}

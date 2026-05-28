import sys

with open('c:/Users/yahme/El7a2ny_backend/El7a2ny/El7a2ny_backend/views.py', 'r', encoding='utf-8') as f:
    content = f.read()

bad_string = """    password = request.data.get("password")        # Dynamic regional insights
    region_counts = Incident.objects.values('location__region').annotate(count=Count('incident_id')).order_by('-count')
    all_regions = [r['location__region'] for r in region_counts if r['location__region'] and r['location__region'] != 'Unknown']
    
    active_areas = all_regions[:3] if len(all_regions) >= 3 else (all_regions + ['Cairo', 'Giza', 'Alexandria'])[:3]
    low_volunteering = all_regions[3:5] if len(all_regions) >= 5 else ['Suez', 'Fayoum']
    inactive_areas = all_regions[-3:] if len(all_regions) >= 8 else ['Aswan', 'Luxor', 'Minya']

    return Response(
        {
            "total_users": total_users,
            "active_alerts": active_alerts,
            "avg_response_time": avg_response_time,
            "success_rate": success_rate,
            "weekly_efficiency": weekly_efficiency,
            "regional_insights": {
                "inactive_areas": inactive_areas,
                "low_volunteering_areas": low_volunteering,
                "active_volunteering_areas": active_areas
            }
        }
    )"""

content = content.replace(bad_string, '    password = request.data.get("password")')

old_response = """        return Response(
            {
                "total_users": total_users,
                "active_alerts": active_alerts,
                "avg_response_time": avg_response_time,
                "success_rate": success_rate,
                "weekly_efficiency": weekly_efficiency,
            }
        )"""

new_response = """        # Dynamic regional insights
        region_counts = Incident.objects.values('location__region').annotate(count=Count('incident_id')).order_by('-count')
        all_regions = [r['location__region'] for r in region_counts if r['location__region'] and r['location__region'] != 'Unknown']
        
        active_areas = all_regions[:3] if len(all_regions) >= 3 else (all_regions + ['Cairo', 'Giza', 'Alexandria'])[:3]
        low_volunteering = all_regions[3:5] if len(all_regions) >= 5 else ['Suez', 'Fayoum']
        inactive_areas = all_regions[-3:] if len(all_regions) >= 8 else ['Aswan', 'Luxor', 'Minya']

        return Response(
            {
                "total_users": total_users,
                "active_alerts": active_alerts,
                "avg_response_time": avg_response_time,
                "success_rate": success_rate,
                "weekly_efficiency": weekly_efficiency,
                "regional_insights": {
                    "inactive_areas": inactive_areas,
                    "low_volunteering_areas": low_volunteering,
                    "active_volunteering_areas": active_areas
                }
            }
        )"""

content = content.replace(old_response, new_response)

with open('c:/Users/yahme/El7a2ny_backend/El7a2ny/El7a2ny_backend/views.py', 'w', encoding='utf-8') as f:
    f.write(content)

print('Patch applied successfully')
